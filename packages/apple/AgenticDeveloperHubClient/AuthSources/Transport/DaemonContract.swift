#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// The contract the local `adhd` daemon must honor, and the single source of
/// truth for the URLs this client targets.
///
/// The daemon is a **transparent caching reverse-proxy**: it serves cached
/// entities from its own local store and forwards everything else to the
/// backend. It accepts every request other than its own `/health` verbatim —
/// same method, headers (including `Authorization: Bearer`), body, and response
/// semantics as the backend — so the generated `Client` is byte-identical
/// whether it points at the backend or the daemon.
///
/// The real daemon does not exist yet; this type defines what it must implement
/// and what `MockDaemonServer` reproduces in tests.
public enum DaemonContract {

    /// Production backend base URL — the `Direct` transport target.
    public static let backendURL = URL(string: "https://api.agenticdeveloperhub.com")!

    /// Fixed loopback port the daemon listens on (Stenographer model — a fixed
    /// port in the dynamic range rather than a discovered one). This is the
    /// canonical value the `adhd` daemon effort must adopt.
    public static let port = 22850

    /// Base URL for the local daemon at the given port.
    public static func daemonURL(port: Int = port) -> URL {
        URL(string: "http://127.0.0.1:\(port)")!
    }

    /// Liveness path the resolver probes. The daemon must answer `200 OK` with a
    /// ``HealthStatus`` JSON body when healthy.
    public static let healthPath = "/health"

    /// Full liveness URL the ``TransportResolver`` probes for the given port.
    public static func healthURL(port: Int = port) -> URL {
        daemonURL(port: port).appendingPathComponent(String(healthPath.dropFirst()))
    }

    /// Wire shape of `GET /health`. The client only requires `status`; the daemon
    /// may include additional fields (decoding ignores unknowns).
    public struct HealthStatus: Codable, Sendable {
        public let status: String
        public let version: String?

        public init(status: String, version: String? = nil) {
            self.status = status
            self.version = version
        }
    }
}
