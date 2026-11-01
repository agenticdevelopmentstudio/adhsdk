import Testing

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

@testable import AgenticDeveloperHubAuth
@testable import AgenticDeveloperHubClient

/// Tests for the daemon-vs-direct decision. The override paths and caching are
/// fully hermetic (injected probe); two cases exercise the real network probe
/// against ``MockDaemonServer`` (up ⇒ daemon) and a dead port (down ⇒ direct).
@Suite("TransportResolver")
struct TransportResolverTests {

    /// A resolver with an injected probe of fixed outcome, counting invocations.
    private func resolver(
        override: TransportResolver.Override,
        probeResult: Bool,
        calls: Box<Int>
    ) -> TransportResolver {
        TransportResolver(override: override, port: DaemonContract.port) { _ in
            calls.set(calls.get + 1)
            return probeResult
        }
    }

    @Test("forceDirect resolves Direct without probing")
    func forceDirectSkipsProbe() async {
        let calls = Box(0)
        let r = resolver(override: .forceDirect, probeResult: true, calls: calls)
        #expect(await r.resolve() == .direct)
        #expect(calls.get == 0)
    }

    @Test("forceDaemon resolves Daemon without probing")
    func forceDaemonSkipsProbe() async {
        let calls = Box(0)
        let r = resolver(override: .forceDaemon, probeResult: false, calls: calls)
        #expect(await r.resolve() == .daemon)
        #expect(calls.get == 0)
    }

    @Test("auto resolves Daemon when the probe succeeds")
    func autoDaemonWhenHealthy() async {
        let r = resolver(override: .auto, probeResult: true, calls: Box(0))
        #expect(await r.resolve() == .daemon)
    }

    @Test("auto falls back to Direct when the probe fails")
    func autoDirectWhenUnhealthy() async {
        let r = resolver(override: .auto, probeResult: false, calls: Box(0))
        #expect(await r.resolve() == .direct)
    }

    @Test("resolve caches; reresolve probes again")
    func cachesUntilReresolve() async {
        let calls = Box(0)
        let r = resolver(override: .auto, probeResult: true, calls: calls)

        #expect(await r.resolve() == .daemon)
        #expect(await r.resolve() == .daemon)  // served from cache
        #expect(calls.get == 1)

        #expect(await r.reresolve() == .daemon)  // forces a fresh probe
        #expect(calls.get == 2)
        #expect(await r.cachedKind == .daemon)
    }

    @Test("fromUserDefaults forces Direct when useDirectMode is set")
    func userDefaultsForcesDirect() {
        let defaults = UserDefaults(suiteName: "TransportResolverTests.\(UUID().uuidString)")!
        defaults.set(true, forKey: "useDirectMode")
        #expect(TransportResolver.fromUserDefaults(defaults).override == .forceDirect)

        defaults.set(false, forKey: "useDirectMode")
        #expect(TransportResolver.fromUserDefaults(defaults).override == .auto)
    }

    @Test("real probe: resolves Daemon against a live mock server")
    func realProbeDaemonUp() async throws {
        let server = MockDaemonServer()
        let port = try server.start()
        defer { server.stop() }

        let r = TransportResolver(override: .auto, port: Int(port), probeTimeout: 2)
        #expect(await r.resolve() == .daemon)
    }

    @Test("real probe: falls back to Direct when nothing is listening")
    func realProbeDaemonDown() async throws {
        // Bind a port, learn it, then release it so the probe hits a dead port.
        let server = MockDaemonServer()
        let port = try server.start()
        server.stop()

        let r = TransportResolver(override: .auto, port: Int(port), probeTimeout: 1)
        #expect(await r.resolve() == .direct)
    }

    @Test("ADHClient.resolved wires to the resolver's choice")
    func resolvedClientUsesChosenTransport() async {
        let daemon = await ADHClient.resolved(using: TransportResolver(override: .forceDaemon))
        #expect(daemon.transportKind == .daemon)

        let direct = await ADHClient.resolved(using: TransportResolver(override: .forceDirect))
        #expect(direct.transportKind == .direct)
    }
}
