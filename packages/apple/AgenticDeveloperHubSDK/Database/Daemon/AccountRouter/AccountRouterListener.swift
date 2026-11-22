#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation
import Network

enum AccountRouterListenerError: Error, Equatable, Sendable {
    case cancelledBeforeReady
    case alreadyStarted
    case readyWithoutPort
    case timedOut
}

/// The router's `NWListener`, pinned to 127.0.0.1. Follows DaemonKit's
/// `HTTPServer.start` pattern: one claimed listener, a ready continuation
/// resumed exactly once, and a start timeout that bounds a `.waiting` bind.
final class AccountRouterListener: @unchecked Sendable {
    /// Called once per accepted connection, with the closure that hands its
    /// accept back when it ends (see `acceptLimit`).
    typealias Admitted = @Sendable (NWConnection, _ ended: @escaping @Sendable () -> Void) -> Void

    private let requestedPort: UInt16
    private let acceptLimit: Int?
    private let onConnection: Admitted
    private let queue = DispatchQueue(label: "account-router.listener", qos: .userInitiated)
    private let lock = NSLock()
    private var listener: NWListener?
    private var readyContinuation: CheckedContinuation<UInt16, Error>?
    /// The listener the pending continuation belongs to: only that listener's
    /// state changes and that start's timeout may resume it.
    private var readyOwner: NWListener?
    private let beginListening: @Sendable (NWListener, DispatchQueue) -> Void
    private var ready = false
    private var lostHandler: (@Sendable () -> Void)?

    /// Called when a listener that was ready fails (the port is gone, not
    /// stopped), so the owner can bind again. A `stop()` never calls it.
    var onLost: (@Sendable () -> Void)? {
        get { lock.withLock { lostHandler } }
        set { lock.withLock { lostHandler = newValue } }
    }

    /// `beginListening` is a test seam: the default starts the listener.
    convenience init(
        port: UInt16,
        beginListening: @escaping @Sendable (NWListener, DispatchQueue) -> Void = { $0.start(queue: $1) },
        onConnection: @escaping @Sendable (NWConnection) -> Void
    ) {
        self.init(port: port, acceptLimit: nil, beginListening: beginListening) { connection, _ in
            onConnection(connection)
        }
    }

    /// With `acceptLimit`, at most that many connections are accepted and not
    /// yet ended (each calls its `ended` closure once). Past it the listener
    /// stops accepting (`NWListener.newConnectionLimit`) and further clients
    /// wait in the kernel's listen backlog: not refused, and holding no
    /// descriptor in this process.
    init(
        port: UInt16,
        acceptLimit: Int?,
        beginListening: @escaping @Sendable (NWListener, DispatchQueue) -> Void = { $0.start(queue: $1) },
        onAdmitted: @escaping Admitted
    ) {
        self.beginListening = beginListening
        self.requestedPort = port
        self.acceptLimit = acceptLimit.map { max(1, $0) }
        self.onConnection = onAdmitted
    }

    var isListening: Bool {
        lock.withLock { listener != nil && ready }
    }

    @discardableResult
    func start(timeout: TimeInterval = 5) async throws -> UInt16 {
        let params = NWParameters.tcp
        let port = requestedPort == 0 ? NWEndpoint.Port.any : (NWEndpoint.Port(rawValue: requestedPort) ?? .any)
        params.requiredLocalEndpoint = NWEndpoint.hostPort(host: .ipv4(.loopback), port: port)
        let created = try NWListener(using: params)
        if let acceptLimit { created.newConnectionLimit = acceptLimit }
        // Weak: the listener owns this handler.
        created.newConnectionHandler = { [weak created, onConnection, queue, acceptLimit] connection in
            let once = OnceFlag()
            onConnection(connection) { [weak created] in
                // The listener's own queue owns `newConnectionLimit`.
                guard acceptLimit != nil, once.claim(), let listener = created else { return }
                queue.async { [weak listener] in listener?.newConnectionLimit += 1 }
            }
        }
        created.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .ready:
                guard let bound = created.port?.rawValue else {
                    self.resumeReady(for: created, .failure(AccountRouterListenerError.readyWithoutPort))
                    return
                }
                let current = self.lock.withLock { () -> Bool in
                    guard self.listener === created else { return false }
                    self.ready = true
                    return true
                }
                guard current else { return }
                AccountRouterLog.logger.info("account router listening on 127.0.0.1:\(bound, privacy: .public)")
                self.resumeReady(for: created, .success(bound))
            case .waiting(let error):
                let reason = AccountRouterLog.scrub(error.localizedDescription)
                AccountRouterLog.logger.warning("account router waiting to bind: \(reason, privacy: .public)")
            case .failed(let error):
                let reason = AccountRouterLog.scrub(error.localizedDescription)
                AccountRouterLog.logger.error("account router listener failed: \(reason, privacy: .public)")
                let lost = self.lock.withLock { () -> (@Sendable () -> Void)? in
                    guard self.listener === created else { return nil }
                    defer {
                        self.ready = false
                        self.listener = nil
                    }
                    return self.ready ? self.lostHandler : nil
                }
                self.resumeReady(for: created, .failure(error))
                lost?()
            case .cancelled:
                self.lock.withLock { if self.listener === created { self.ready = false } }
                self.resumeReady(for: created, .failure(AccountRouterListenerError.cancelledBeforeReady))
            default:
                break
            }
        }
        let claimed = lock.withLock { () -> Bool in
            guard listener == nil else { return false }
            listener = created
            return true
        }
        guard claimed else {
            created.cancel()
            throw AccountRouterListenerError.alreadyStarted
        }
        do {
            return try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<UInt16, Error>) in
                    lock.withLock {
                        readyContinuation = continuation
                        readyOwner = created
                    }
                    // A start cancelled before this point already ran `onCancel`,
                    // when there was no continuation to resume: stop waiting now.
                    if Task.isCancelled {
                        resumeReady(for: created, .failure(CancellationError()))
                        return
                    }
                    beginListening(created, queue)
                    queue.asyncAfter(deadline: .now() + timeout) { [weak self] in
                        self?.resumeReady(for: created, .failure(AccountRouterListenerError.timedOut))
                    }
                }
            } onCancel: {
                self.stop(ifCurrent: created)
                // A listener that never started reports no `.cancelled`; end the wait here.
                self.resumeReady(for: created, .failure(CancellationError()))
            }
        } catch {
            created.cancel()
            lock.withLock {
                if listener === created {
                    listener = nil
                    ready = false
                }
            }
            throw error
        }
    }

    func stop() { stop(ifCurrent: nil) }

    /// With `only`, stops just that listener, so a cancelled start can never
    /// tear down a newer one.
    private func stop(ifCurrent only: NWListener?) {
        let current = lock.withLock { () -> NWListener? in
            let current = listener
            if let only, current !== only { return nil }
            listener = nil
            ready = false
            return current
        }
        current?.cancel()
    }

    private func resumeReady(for owner: NWListener, _ result: Result<UInt16, Error>) {
        let continuation = lock.withLock { () -> CheckedContinuation<UInt16, Error>? in
            guard readyOwner === owner else { return nil }
            let pending = readyContinuation
            readyContinuation = nil
            readyOwner = nil
            return pending
        }
        continuation?.resume(with: result)
    }
}

/// True exactly once, from any thread.
private final class OnceFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var claimed = false

    func claim() -> Bool {
        lock.withLock {
            defer { claimed = true }
            return !claimed
        }
    }
}
#endif
