import Foundation
import os
import AgenticDeveloperHubSDKDatabase
import AgenticDeveloperHubSDKSync
import AgenticDeveloperHubSDKIntegrations
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

        public init(sync: HubMailSync, writeLabels: @escaping @Sendable (HubMailLabelWrite) async throws -> Void) {
            self.sync = sync
            self.writeLabels = writeLabels
        }
    }

    public nonisolated static let signedOutMessage =
        "Sign in to the Agentic Developer Hub in Settings to read hub mail."

    public private(set) var status: Status = .signedOut {
        didSet { if status != oldValue { onChange() } }
    }

    /// Called on the main actor whenever `status` changes.
    public var onChange: @MainActor () -> Void = {}

    public nonisolated let client: MailClient

    private let connect: @MainActor () throws -> Connection
    private let syncInterval: TimeInterval?
    private let current: BridgeBox
    private var sync: HubMailSync?
    private var trigger: PeriodicTriggerSource?

    private static let log = Logger(subsystem: "com.agenticdevelopmentstudio.hubmail", category: "service")

    /// - Parameters:
    ///   - syncInterval: seconds between background pulls, or nil for none
    ///     (the bridge's `syncNow` request still pulls on demand).
    ///   - connect: builds the sync and label writer for the identity that
    ///     just signed in. A throw lands in `.failed` with its message.
    public init(syncInterval: TimeInterval? = 300, connect: @escaping @MainActor () throws -> Connection) {
        let box = BridgeBox()
        self.current = box
        self.connect = connect
        self.syncInterval = syncInterval
        self.client = MailClient { data in
            let request = try JSONDecoder().decode(MailRequest.self, from: data)
            guard let bridge = box.bridge else {
                return try JSONEncoder().encode(MailResponse.failure(Self.signedOutMessage))
            }
            return try JSONEncoder().encode(await bridge.respond(to: request))
        }
    }

    /// Opens the mirror for the identity now signed in and pulls once. A
    /// second call while connected does nothing.
    public func signedIn() async {
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
        current.bridge = HubMailBridge(
            store: sync.store,
            writeLabels: connection.writeLabels,
            syncNow: { await sync.syncNow() }
        )
        status = .connected
        if let syncInterval {
            let trigger = PeriodicTriggerSource(interval: syncInterval)
            self.trigger = trigger
            await sync.engine.attach(trigger)
        }
        await sync.syncNow()
    }

    /// Purges the departing identity's mail and stops syncing. Reads fail
    /// with `signedOutMessage` from the moment this is called.
    public func signedOut() async {
        guard let sync else {
            if case .failed = status { status = .signedOut }
            return
        }
        self.sync = nil
        current.bridge = nil
        trigger?.stop()
        trigger = nil
        status = .signedOut
        do {
            try await sync.signOut()
        } catch {
            Self.log.error("hub mail purge failed: \(error.localizedDescription, privacy: .public)")
            status = .failed("The hub mail copy could not be cleared: \(error.localizedDescription)")
        }
        await sync.engine.stop()
    }

    /// Asks for a pull now, when connected.
    public func syncNow() async {
        await sync?.syncNow()
    }
}

/// The bridge `client` answers through, read off the main actor.
private final class BridgeBox: Sendable {
    private let lock = OSAllocatedUnfairLock<HubMailBridge?>(initialState: nil)

    var bridge: HubMailBridge? {
        get { lock.withLock { $0 } }
        set { lock.withLock { $0 = newValue } }
    }
}
