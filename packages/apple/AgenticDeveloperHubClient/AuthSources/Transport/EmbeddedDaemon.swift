import Foundation

/// A daemon hosted inside the app process rather than reached over a port.
///
/// Lives here, in the client, because this is the one module both sides of the
/// seam already depend on. The concrete daemon (`LocalDaemon`, adh-daemon's
/// `ADHDPipeline`) depends on agentictoolkit, so agentictoolkit's hub modules
/// cannot name it without a cycle; they hold `any EmbeddedDaemon` and the host,
/// which links both, passes the concrete one in.
///
/// Every lifecycle call must be safe to repeat (`start` on a started daemon,
/// `stop` on a stopped one, `shutdown` before any `start`): scene callbacks
/// arrive in whatever order UIKit delivers them.
public protocol EmbeddedDaemon: Sendable {
    /// Brings the daemon up: the sync runtime and its periodic loop.
    func start() async
    /// Parks it while the app is in the background; `start()` resumes it.
    func stop() async
    /// Asks for a sync pass now rather than at the next tick.
    func kickSync() async
    /// Final teardown at process exit. The daemon cannot be restarted after.
    func shutdown() async
    /// The transport the app's client uses to reach this daemon.
    func transport() -> APITransport
}
