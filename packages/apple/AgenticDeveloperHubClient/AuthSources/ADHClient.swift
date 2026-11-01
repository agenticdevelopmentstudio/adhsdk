import OpenAPIRuntime

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// The entry point to the Agentic Developer Hub API.
///
/// `ADHClient` is a thin façade over the generated clients: it wires a chosen
/// ``APITransport`` (Direct or Daemon) to the typed surface and attaches
/// either the ``AuthenticationMiddleware`` (bearer-only) or the
/// ``SessionRefreshMiddleware`` (bearer + refresh-and-retry) so every request
/// carries the bearer token.
///
/// It lives in AgenticDeveloperHubAuth, the sign-in tier, which generates only
/// the sign-in and session operations (``authAPI``). The whole typed API is
/// `api`, added by AgenticDeveloperHubClient — link that, and
/// `client.api.getWorkspaces(...)` is there; link only this, and sign-in costs
/// a few thousand lines instead of the full client.
///
/// The transport is the only point of variation: Direct and Daemon produce an
/// identical `Client`, differing only by the `(serverURL, transport)` pair the
/// ``APITransport`` carries. Pick one explicitly via ``direct(credentials:)`` /
/// ``daemon(credentials:)``, or let ``TransportResolver`` choose at runtime.
public struct ADHClient: Sendable {

    /// The generated sign-in and session operations — the paths
    /// `openapi-generator-auth-config.yaml` keeps. The whole API is `api`, in
    /// AgenticDeveloperHubClient.
    public let authAPI: HubAuthClient

    /// The transport this client is wired to. Kept so a later raw-request
    /// escape hatch can route un-generated endpoints through the same
    /// `(serverURL, transport)` pair and middleware chain.
    public let transport: APITransport

    /// Which endpoint this client is wired to — useful for diagnostics and for
    /// the resolver's caching.
    public var transportKind: TransportKind { transport.kind }

    /// The credential store backing the attached middleware. Held so the auth
    /// convenience wrappers can persist tokens through it.
    let credentials: any CredentialStore

    /// Non-nil only for clients built with `init(transport:session:onSessionExpired:)`.
    let session: (any SessionStore)?

    /// The middleware chain every request runs through: `rawJSON` sends
    /// un-generated endpoints through it, and AgenticDeveloperHubClient builds
    /// the full `api` on it, so both get the same auth/refresh behavior.
    public let middlewares: [any ClientMiddleware]

    /// Bearer-only client (no refresh). Kept for callers that hold a
    /// `CredentialStore` — the daemon's `EnvCredentialProvider` fallback,
    /// BitbagIOS, scripts.
    /// - Parameters:
    ///   - transport: the Direct/Daemon transport seam to talk through.
    ///   - credentials: the credential store the auth middleware reads from and
    ///     the auth wrappers write to. Defaults to the Keychain-backed store.
    public init(
        transport: APITransport,
        credentials: any CredentialStore = KeychainCredentialStore()
    ) {
        self.transport = transport
        self.credentials = credentials
        self.session = nil
        self.middlewares = [AuthenticationMiddleware(credentials: credentials)]
        self.authAPI = HubAuthClient(
            serverURL: transport.serverURL,
            transport: transport.transport,
            middlewares: middlewares
        )
    }

    /// Session client: bearer + refresh-and-retry. `onSessionExpired` fires
    /// (off the main actor) when a refresh is rejected and the store has
    /// been cleared — the app shows sign-in.
    public init(
        transport: APITransport,
        session: any SessionStore,
        onSessionExpired: @escaping @Sendable () -> Void = {}
    ) {
        self.transport = transport
        self.credentials = session
        self.session = session
        self.middlewares = [SessionRefreshMiddleware(session: session, onSessionExpired: onSessionExpired)]
        self.authAPI = HubAuthClient(
            serverURL: transport.serverURL,
            transport: transport.transport,
            middlewares: middlewares
        )
    }
}

extension ADHClient {

    /// A client wired straight to the backend over HTTPS.
    public static func direct(
        credentials: any CredentialStore = KeychainCredentialStore()
    ) -> ADHClient {
        ADHClient(transport: .direct(), credentials: credentials)
    }

    /// A client wired to the local `adhd` daemon. Use only when the daemon is
    /// known to be reachable — prefer ``TransportResolver`` to choose safely.
    public static func daemon(
        credentials: any CredentialStore = KeychainCredentialStore()
    ) -> ADHClient {
        ADHClient(transport: .daemon(), credentials: credentials)
    }

    /// The recommended entry point: ask a ``TransportResolver`` whether the
    /// daemon is reachable and wire the client to whichever transport it picks
    /// (Daemon if up, else Direct). Defaults to an auto-resolving probe.
    public static func resolved(
        using resolver: TransportResolver = TransportResolver(),
        credentials: any CredentialStore = KeychainCredentialStore()
    ) async -> ADHClient {
        let transport: APITransport = switch await resolver.resolve() {
        case .daemon: .daemon(port: resolver.port)
        case .direct: .direct()
        }
        return ADHClient(transport: transport, credentials: credentials)
    }

    /// A session-backed client wired straight to the backend over HTTPS.
    public static func direct(
        session: any SessionStore,
        onSessionExpired: @escaping @Sendable () -> Void = {}
    ) -> ADHClient {
        ADHClient(transport: .direct(), session: session, onSessionExpired: onSessionExpired)
    }

    /// A session-backed client wired to the local `adhd` daemon. Use only when
    /// the daemon is known to be reachable — prefer ``TransportResolver`` to
    /// choose safely.
    public static func daemon(
        session: any SessionStore,
        port: Int = DaemonContract.port,
        onSessionExpired: @escaping @Sendable () -> Void = {}
    ) -> ADHClient {
        ADHClient(transport: .daemon(port: port), session: session, onSessionExpired: onSessionExpired)
    }

    /// The recommended session-backed entry point: ask a ``TransportResolver``
    /// whether the daemon is reachable and wire the client to whichever
    /// transport it picks (Daemon if up, else Direct).
    public static func resolved(
        using resolver: TransportResolver = TransportResolver(),
        session: any SessionStore,
        onSessionExpired: @escaping @Sendable () -> Void = {}
    ) async -> ADHClient {
        let transport: APITransport = switch await resolver.resolve() {
        case .daemon: .daemon(port: resolver.port)
        case .direct: .direct()
        }
        return ADHClient(transport: transport, session: session, onSessionExpired: onSessionExpired)
    }
}
