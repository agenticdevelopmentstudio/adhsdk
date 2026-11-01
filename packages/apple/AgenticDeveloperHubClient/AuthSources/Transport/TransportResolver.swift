#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Decides whether to talk to the local `adhd` daemon or straight to the
/// backend, and caches that decision.
///
/// In `.auto` mode it probes the daemon's `GET /health` with a bounded timeout:
/// `200` ⇒ Daemon, anything else (refused, error, timeout, non-200) ⇒ Direct.
/// Direct is the guaranteed fallback, so the client always works. The resolver
/// **does not launch** the daemon — it only detects one that is already running.
///
/// It resolves once and caches the ``TransportKind``; ``reresolve()`` forces a
/// fresh probe (e.g. after the daemon is installed mid-session).
public actor TransportResolver {

    /// How the transport is chosen. `.auto` probes; the `force*` cases skip the
    /// probe entirely (an explicit operator/test override).
    public enum Override: String, Sendable {
        case auto
        case forceDirect
        case forceDaemon
    }

    public nonisolated let override: Override
    public nonisolated let port: Int
    private let probe: @Sendable (URL) async -> Bool
    private var cached: TransportKind?

    /// - Parameters:
    ///   - override: probe (`.auto`) or force a transport.
    ///   - port: the daemon's loopback port to probe.
    ///   - probeTimeout: how long the health probe waits before treating the
    ///     daemon as down (seconds).
    public init(
        override: Override = .auto,
        port: Int = DaemonContract.port,
        probeTimeout: TimeInterval = 2
    ) {
        self.init(override: override, port: port, probe: Self.makeHealthProbe(timeout: probeTimeout))
    }

    /// Test seam: inject a probe instead of hitting the network.
    init(override: Override, port: Int, probe: @escaping @Sendable (URL) async -> Bool) {
        self.override = override
        self.port = port
        self.probe = probe
    }

    /// The cached decision, if `resolve()`/`reresolve()` has run.
    public var cachedKind: TransportKind? { cached }

    /// Resolve, returning the cached decision if one exists.
    @discardableResult
    public func resolve() async -> TransportKind {
        if let cached { return cached }
        return await reresolve()
    }

    /// Probe again and replace the cached decision.
    @discardableResult
    public func reresolve() async -> TransportKind {
        let kind = await decide()
        cached = kind
        return kind
    }

    private func decide() async -> TransportKind {
        switch override {
        case .forceDirect: return .direct
        case .forceDaemon: return .daemon
        case .auto: return await probe(DaemonContract.healthURL(port: port)) ? .daemon : .direct
        }
    }

    /// Production probe: a single bounded `GET` that returns `true` only on `200`.
    /// A refused connection or timeout throws and maps to `false` (Direct).
    private static func makeHealthProbe(timeout: TimeInterval) -> @Sendable (URL) async -> Bool {
        { url in
            let configuration = URLSessionConfiguration.ephemeral
            configuration.waitsForConnectivity = false
            configuration.timeoutIntervalForRequest = timeout
            configuration.timeoutIntervalForResource = timeout
            let session = URLSession(configuration: configuration)
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            do {
                let (_, response) = try await session.data(for: request)
                return (response as? HTTPURLResponse)?.statusCode == 200
            } catch {
                return false
            }
        }
    }
}

extension TransportResolver {

    /// Honors a `useDirectMode` user default (temporal's escape hatch): when set,
    /// forces Direct; otherwise auto-resolves.
    public static func fromUserDefaults(
        _ defaults: UserDefaults = .standard,
        port: Int = DaemonContract.port
    ) -> TransportResolver {
        TransportResolver(
            override: defaults.bool(forKey: "useDirectMode") ? .forceDirect : .auto,
            port: port
        )
    }
}
