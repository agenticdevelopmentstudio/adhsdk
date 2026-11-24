import Foundation

/// Why one call to the daemon hosting `MailIntegrationService` got no answer,
/// as the host's IPC layer reports it. The host maps its own errors onto these
/// (an XPC client's timeout, a dropped connection, anything else), so the
/// wording below stays in one place whatever the transport is.
public enum MailTransportFailure: Error, Equatable, Sendable {
    /// The daemon was reached but did not answer in time.
    case timedOut
    /// The connection was refused or dropped.
    case connectionDropped
    /// Any other failure to reach the daemon, with a description of it.
    case unreachable(String)
}

/// The rules for a `MailClient` whose service lives in a daemon: how long each
/// request may wait, that nothing is retried, that an empty reply is an error,
/// and the sentence each failure is reported as. A host app and its command-line
/// tool both build their client through this, so the two cannot drift apart.
public enum MailDaemonTransport {
    /// Longer than the SDK's own 300 s cap on a browser sign-in, which runs
    /// inside the daemon while the call waits for its answer.
    public static let callTimeout: TimeInterval = 360

    /// How long to wait for `request`'s answer; nil waits until the daemon
    /// answers or the connection drops.
    ///
    /// `syncNow` gets no deadline. It answers when the whole sync ends, joins
    /// one already running, and quota pacing caps it at about 40 messages a
    /// second, so a large first sync can take far longer than any fixed
    /// deadline while the daemon is healthy. A dead daemon still ends the call
    /// through the dropped connection. Every other request, and bytes that are
    /// not a request at all, keep `callTimeout`.
    public static func timeout(for request: Data) -> TimeInterval? {
        if case .syncNow = try? JSONDecoder().decode(MailRequest.self, from: request) { return nil }
        return callTimeout
    }

    /// A `MailClient` over the host's IPC call.
    ///
    /// - Parameters:
    ///   - daemonName: what failure sentences call the daemon (`temporald`).
    ///   - call: one round trip, waiting at most the given time (nil: no
    ///     deadline). It must not retry: `signIn` opens a browser and
    ///     `modifyLabels` writes to Gmail, and a retry after a timeout could do
    ///     either twice.
    ///   - classify: maps the host's IPC error onto a `MailTransportFailure`.
    ///   - onFailure: sees the underlying error before it becomes a sentence.
    public static func makeClient(
        daemonName: String,
        call: @escaping @Sendable (Data, TimeInterval?) async throws -> Data,
        classify: @escaping @Sendable (any Error) -> MailTransportFailure,
        onFailure: @escaping @Sendable (any Error) -> Void = { _ in }
    ) -> MailClient {
        MailClient(transport: { request in
            try await send(request, daemonName: daemonName, call: call,
                           classify: classify, onFailure: onFailure)
        })
    }

    /// One `MailRequest` → `MailResponse` round trip, as JSON bytes.
    public static func send(
        _ request: Data,
        daemonName: String,
        call: @Sendable (Data, TimeInterval?) async throws -> Data,
        classify: @Sendable (any Error) -> MailTransportFailure,
        onFailure: @Sendable (any Error) -> Void = { _ in }
    ) async throws -> Data {
        let reply: Data
        do {
            reply = try await call(request, timeout(for: request))
        } catch {
            onFailure(error)
            throw remoteError(for: classify(error), daemonName: daemonName)
        }
        guard !reply.isEmpty else { throw MailClientError.remote("\(daemonName) dropped the reply") }
        return reply
    }

    /// The sentence each failure is reported as.
    public static func remoteError(for failure: MailTransportFailure, daemonName: String) -> MailClientError {
        switch failure {
        case .timedOut:
            return .remote("\(daemonName) did not answer within \(Int(callTimeout)) s")
        case .connectionDropped:
            return .remote("cannot reach \(daemonName): the connection was refused or dropped "
                + "(is \(daemonName) running, and signed by the same team as this tool?)")
        case .unreachable(let detail):
            return .remote("cannot reach \(daemonName): \(detail)")
        }
    }
}
