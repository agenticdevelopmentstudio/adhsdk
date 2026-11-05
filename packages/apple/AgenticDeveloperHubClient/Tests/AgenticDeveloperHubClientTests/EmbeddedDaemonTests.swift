import Foundation
import OpenAPIURLSession
import Testing
@testable import AgenticDeveloperHubAuth
@testable import AgenticDeveloperHubClient

/// `EmbeddedDaemon` is the only view of the in-process daemon that the hub
/// modules get: adhsdk cannot link `ADHDPipeline` without a cycle.
/// These pin the contract a conformer is held to — lifecycle calls reach it,
/// and the transport it hands out is its own.
@Suite("EmbeddedDaemon")
struct EmbeddedDaemonTests {

    actor FakeDaemon: EmbeddedDaemon {
        private(set) var calls: [String] = []
        func start() async { calls.append("start") }
        func stop() async { calls.append("stop") }
        func kickSync() async { calls.append("kickSync") }
        func shutdown() async { calls.append("shutdown") }
        nonisolated func transport() -> APITransport {
            APITransport(kind: .daemon, serverURL: DaemonContract.daemonURL(), transport: URLSessionTransport())
        }
    }

    @Test("lifecycle calls reach the conformer through the existential, in order")
    func lifecycleThroughExistential() async {
        let fake = FakeDaemon()
        let daemon: any EmbeddedDaemon = fake
        await daemon.start()
        await daemon.kickSync()
        await daemon.stop()
        await daemon.shutdown()
        #expect(await fake.calls == ["start", "kickSync", "stop", "shutdown"])
    }

    @Test("the transport is the daemon's, not a direct one")
    func transportIsDaemonKind() {
        let daemon: any EmbeddedDaemon = FakeDaemon()
        #expect(daemon.transport().kind == .daemon)
    }
}
