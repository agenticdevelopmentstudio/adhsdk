import OpenAPIRuntime
import OpenAPIURLSession

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Which endpoint the client talks to — the ``TransportResolver``'s decision.
public enum TransportKind: String, Sendable {
    /// HTTPS straight to the backend.
    case direct
    /// HTTP to the local `adhd` daemon (transparent caching proxy).
    case daemon
}

/// A `ClientTransport` paired with the server URL it targets.
///
/// This is the seam the resolver picks between and that ``ADHClient`` builds its
/// generated `Client` from. swift-openapi-runtime takes the server URL on the
/// `Client` (not the transport), so Direct vs Daemon is fully captured by
/// `(serverURL, transport)` — the generated client is identical across both.
public struct APITransport: Sendable {

    public let kind: TransportKind
    public let serverURL: URL
    public let transport: any ClientTransport

    public init(kind: TransportKind, serverURL: URL, transport: any ClientTransport) {
        self.kind = kind
        self.serverURL = serverURL
        self.transport = transport
    }
}

extension APITransport {

    /// Direct transport: HTTPS to the backend via a standard `URLSession`.
    /// - Parameter transport: overridable for tests (inject a mock `ClientTransport`).
    public static func direct(
        serverURL: URL = DaemonContract.backendURL,
        transport: any ClientTransport = URLSessionTransport()
    ) -> APITransport {
        APITransport(kind: .direct, serverURL: serverURL, transport: transport)
    }

    /// Daemon transport: HTTP to the local daemon via an ephemeral `URLSession`
    /// (no shared cache/cookies; does not wait for connectivity since the
    /// resolver has already confirmed the daemon is up).
    /// - Parameter transport: overridable for tests (inject a mock `ClientTransport`).
    public static func daemon(
        port: Int = DaemonContract.port,
        transport: (any ClientTransport)? = nil
    ) -> APITransport {
        APITransport(
            kind: .daemon,
            serverURL: DaemonContract.daemonURL(port: port),
            transport: transport ?? makeDaemonURLSessionTransport()
        )
    }

    /// URLSession transport tuned for the local daemon.
    static func makeDaemonURLSessionTransport() -> URLSessionTransport {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.waitsForConnectivity = false
        configuration.timeoutIntervalForRequest = 30
        return URLSessionTransport(
            configuration: .init(session: URLSession(configuration: configuration))
        )
    }
}
