import Foundation
import os
import AgenticDeveloperHubSDKDatabase
import AgenticDeveloperHubSDKSync
import AgenticDeveloperHubSDKMail
import AgenticDeveloperHubSDKHubMail

/// Keeps Hub Mail open while a hub identity is signed in, and purges it when
/// that identity leaves.
///
/// `client` is one stable `MailClient` for the app's lifetime. While signed
/// in it is answered by a `HubMailBridge` over the mirror; while signed out
/// every request fails with `signedOutMessage`. Windows can hold it from
/// launch and never need to be told about a sign-in.
///
/// The service never reaches the network itself: `connect` builds the sync
/// and the label writer, so tests hand it a scripted transport.
@MainActor
public final class HubMailService {

    public enum Status: Equatable, Sendable {
        case signedOut
        case connected
        case failed(String)
    }

    /// What one signed-in identity reads and writes through.
    public struct Connection: Sendable {
        public let sync: HubMailSync
        public let writeLabels: @Sendable (HubMailLabelWrite) async throws -> Void
        /// Renews the session after the hub refused a pull's token. True when
        /// the pull is worth trying again; false when the session could not be
        /// renewed (the hub unreachable, or no refresh token).
        public let refreshSession: @Sendable () async -> Bool

        public init(
            sync: HubMailSync,
            writeLabels: @escaping @Sendable (HubMailLabelWrite) async throws -> Void,
            refreshSession: @escaping @Sendable () async -> Bool = { false }
        ) {
            self.sync = sync
            self.writeLabels = writeLabels
            self.refreshSession = refreshSession
        }
    }

    public nonisolated static let signedOutMessage =
        "Sign in to the Agentic Developer Hub in Settings to read hub mail."

    /// The status while the hub refuses pulls and the session could not be
    /// renewed. Reads still answer from the mirror.
    public nonisolated static let authRetryMessage =
        "Hub mail could not renew its sign-in, so new mail is not arriving. It will try again shortly."

    public private(set) var status: Status = .signedOut {
        didSet { if status != oldValue { onChange() } }
    }

    /// Called on the main actor whenever `status` changes.
    public var onChange: @MainActor () -> Void = {}

    public nonisolated let client: MailClient

    private let connect: @MainActor () throws -> Connection
    private let syncInterval: TimeInterval?
    private let authRetryDelay: Duration
    private let current: BridgeBox
    private var sync: HubMailSync?
    private var trigger: PeriodicTriggerSource?
    /// The purge `signedOut()` is running. A sign-in waits for it, so a new
    /// identity never opens the mirror while the old one is being cleared
    /// (the purge would delete what the new sync pulled).
    private var signingOut: Task<Void, Never>?
    /// Reads the open sync's events, renewing the session when a pull is refused.
    private var watcher: Task<Void, Never>?
    /// The pull a refused token scheduled, now or after `authRetryDelay`.
    private var authRetry: Task<Void, Never>?

    private static let log = Logger(subsystem: "com.agenticdevelopmentstudio.hubmail", category: "service")

    /// - Parameters:
    ///   - syncInterval: seconds between background pulls, or nil for none
    ///     (the bridge's `syncNow` request still pulls on demand).
    ///   - authRetryDelay: how long to wait before pulling again when the hub
    ///     refused the token and the session could not be renewed.
    ///   - connect: builds the sync and label writer for the identity that
    ///     just signed in. A throw lands in `.failed` with its message.
    public init(
        syncInterval: TimeInterval? = 300,
        authRetryDelay: Duration = .seconds(60),
        connect: @escaping @MainActor () throws -> Connection
    ) {
        let box = BridgeBox()
        self.current = box
        self.connect = connect
        self.syncInterval = syncInterval
        self.authRetryDelay = authRetryDelay
        self.client = MailClient { data in
            let request = try JSONDecoder().decode(MailRequest.self, from: data)
            guard let bridge = box.bridge else {
                return try JSONEncoder().encode(MailResponse.failure(Self.signedOutMessage))
            }
            return try JSONEncoder().encode(await bridge.respond(to: request))
        }
    }

    /// Opens the mirror for the identity now signed in and pulls once. A
    /// second call while connected does nothing. A sign-out still purging
    /// finishes first.
    public func signedIn() async {
        while let pending = signingOut { await pending.value }
        guard sync == nil else { return }
        let connection: Connection
        do {
            connection = try connect()
        } catch {
            Self.log.error("hub mail could not open: \(error.localizedDescription, privacy: .public)")
            status = .failed(error.localizedDescription)
            return
        }
        let sync = connection.sync
        self.sync = sync
        let clock = SyncClock()
        current.bridge = HubMailBridge(
            store: sync.store,
            writeLabels: connection.writeLabels,
            syncNow: { await sync.syncNow() },
            lastSyncAt: { clock.value }
        )
        status = .connected
        watcher = watch(sync, clock: clock, refresh: connection.refreshSession)
        if let syncInterval {
            let trigger = PeriodicTriggerSource(interval: syncInterval)
            self.trigger = trigger
            await sync.engine.attach(trigger)
        }
        await sync.syncNow()
    }

    /// Purges the departing identity's mail and stops syncing. Reads fail
    /// with `signedOutMessage` from the moment this is called.
    ///
    /// With no mirror open (a launch whose restore ended signed out, or a
    /// failed sign-in) it still opens the file through `connect` and purges
    /// it: the mirror outlives the process, so mail a previous launch's
    /// identity left on disk must not be served to whoever signs in next.
    public func signedOut() async {
        while let pending = signingOut { await pending.value }
        let departing = sync
        sync = nil
        current.bridge = nil
        trigger?.stop()
        trigger = nil
        watcher?.cancel()
        watcher = nil
        authRetry?.cancel()
        authRetry = nil
        status = .signedOut
        let purge = Task { await self.purge(departing) }
        signingOut = purge
        await purge.value
        if signingOut == purge { signingOut = nil }
    }

    private func purge(_ departing: HubMailSync?) async {
        let sync: HubMailSync
        if let departing {
            sync = departing
        } else {
            do {
                sync = try connect().sync
            } catch {
                // Nothing reachable to clear; the next sign-in reports the cause.
                Self.log.error("hub mail could not open to purge: \(error.localizedDescription, privacy: .public)")
                return
            }
        }
        do {
            try await sync.signOut()
        } catch {
            Self.log.error("hub mail purge failed: \(error.localizedDescription, privacy: .public)")
            status = .failed("The hub mail copy could not be cleared: \(error.localizedDescription)")
        }
        await sync.engine.stop()
    }

    /// Keeps pulls going past the access token's lifetime. The engine pauses
    /// on a refused token and drops its periodic kicks until a manual one, so
    /// each `.authRequired` renews the session and pulls again. A refusal
    /// right after a renewal, or a renewal that fails, shows
    /// `authRetryMessage` and tries again after `authRetryDelay`; the next
    /// completed cycle clears it. Each completed cycle is also stamped on
    /// `clock`, which the bridge reports as the accounts' `lastSyncAt`.
    private func watch(
        _ sync: HubMailSync,
        clock: SyncClock,
        refresh: @escaping @Sendable () async -> Bool
    ) -> Task<Void, Never> {
        Task { [weak self] in
            var renewedSinceLastCycle = false
            for await event in sync.events {
                guard let service = self, service.sync === sync else { return }
                switch event {
                case .authRequired:
                    let renewed = renewedSinceLastCycle ? false : await refresh()
                    guard service.sync === sync else { return }
                    renewedSinceLastCycle = renewed
                    if renewed {
                        service.pull(sync, after: nil)
                    } else {
                        Self.log.error("hub mail pull refused and the session was not renewed")
                        service.status = .failed(Self.authRetryMessage)
                        service.pull(sync, after: service.authRetryDelay)
                    }
                case .idle:
                    clock.stamp()
                    renewedSinceLastCycle = false
                    if case .failed = service.status { service.status = .connected }
                default:
                    break
                }
            }
        }
    }

    /// A manual pull, which lifts the engine's auth pause.
    private func pull(_ sync: HubMailSync, after delay: Duration?) {
        authRetry?.cancel()
        authRetry = Task { [weak self] in
            if let delay { try? await Task.sleep(for: delay) }
            guard !Task.isCancelled, let self, self.sync === sync else { return }
            await sync.syncNow()
        }
    }

    /// Asks for a pull now, when connected.
    public func syncNow() async {
        await sync?.syncNow()
    }
}

/// The bridge `client` answers through, read off the main actor.
/// When the open mirror's last pull completed, read by the bridge from any thread.
final class SyncClock: Sendable {
    private let lock = OSAllocatedUnfairLock<String?>(initialState: nil)

    var value: String? { lock.withLock { $0 } }

    func stamp(_ date: Date = Date()) {
        let text = date.formatted(Date.ISO8601FormatStyle(includingFractionalSeconds: true))
        lock.withLock { $0 = text }
    }
}

private final class BridgeBox: Sendable {
    private let lock = OSAllocatedUnfairLock<HubMailBridge?>(initialState: nil)

    var bridge: HubMailBridge? {
        get { lock.withLock { $0 } }
        set { lock.withLock { $0 = newValue } }
    }
}
