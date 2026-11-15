import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

struct SessionDaemonConfigurationTests {

    private func makeConfiguration(
        label: String = "a.b",
        subsystem: String? = nil,
        httpPort: UInt16 = 1,
        support: String = "/tmp/x",
        drop: String = "/tmp/x/events",
        retentionDays: Int = 7
    ) -> SessionDaemonConfiguration {
        SessionDaemonConfiguration(
            label: label,
            subsystem: subsystem,
            daemonVersion: "1.0",
            httpPort: httpPort,
            supportDirectory: URL(fileURLWithPath: support),
            socketPath: "/tmp/x/s.sock",
            dropDirectory: URL(fileURLWithPath: drop),
            hook: ClaudeHookConfiguration(
                name: "n", marker: "# n", hookBinaryPath: "/bin/n",
                dropDirectory: drop, settingsURL: URL(fileURLWithPath: "/tmp/x/settings.json")),
            retentionDays: retentionDays,
            summariesDefaultEnabled: false)
    }

    @Test("V1: subsystem defaults to the label")
    func testV1_subsystemDefault() {
        #expect(makeConfiguration().subsystem == "a.b")
    }

    @Test("V2: an explicit subsystem overrides")
    func testV2_explicitSubsystem() {
        #expect(makeConfiguration(subsystem: "c.d").subsystem == "c.d")
    }

    @Test("V3: database and spool paths derive from the support directory")
    func testV3_derivedPaths() {
        let config = makeConfiguration()
        #expect(config.databasePath == "/tmp/x/sessions.db")
        #expect(config.spoolPath == "/tmp/x/ingest.db")
    }

    @Test("V4: errors directory defaults under the drop directory")
    func testV4_errorsDefault() {
        #expect(makeConfiguration().errorsDirectory.path == "/tmp/x/events/errors")
    }

    @Test("V5: retention and interval defaults")
    func testV5_intervalDefaults() {
        let config = makeConfiguration()
        #expect(config.retentionDays == 7)
        #expect(config.livenessCheckInterval == 10)
        #expect(config.retentionCheckInterval == 86400)
    }

    @Test("V6: claude json and plugin path defaults")
    func testV6_optionalDefaults() {
        let config = makeConfiguration()
        #expect(config.claudeJSONPath == nil)
        #expect(config.pluginSearchPaths.isEmpty)
    }

    @Test("V7: test(root:) derives every path from the root")
    func testV7_testRootPaths() {
        let config = SessionDaemonConfiguration.test(root: URL(fileURLWithPath: "/r"))
        #expect(config.supportDirectory.path == "/r")
        #expect(config.socketPath == "/r/capture.sock")
        #expect(config.dropDirectory.path == "/r/events")
        #expect(config.databasePath == "/r/sessions.db")
        #expect(config.spoolPath == "/r/ingest.db")
        #expect(config.errorsDirectory.path == "/r/events/errors")
    }

    @Test("V8: test() identity, port and summaries")
    func testV8_testIdentity() {
        let config = SessionDaemonConfiguration.test()
        #expect(config.label == "test.session-daemon")
        #expect(config.daemonVersion == "0.0.0-test")
        #expect(config.httpPort == 0)
        #expect(config.summariesDefaultEnabled == false)
    }

    @Test("V9: test(root:) hook and account file")
    func testV9_testHook() {
        let config = SessionDaemonConfiguration.test(root: URL(fileURLWithPath: "/r"))
        #expect(config.hook.name == "session-daemon-test")
        #expect(config.hook.marker == "# session-daemon-test-hook")
        #expect(config.hook.settingsURL.path == "/r/settings.json")
        #expect(config.claudeJSONPath == "/r/claude.json")
    }

    @Test("V10: test() roots are unique and carry a UUID")
    func testV10_uniqueRoots() {
        let first = SessionDaemonConfiguration.test().supportDirectory
        let second = SessionDaemonConfiguration.test().supportDirectory
        #expect(first != second)
        for url in [first, second] {
            let name = url.lastPathComponent
            #expect(name.hasPrefix("session-daemon-test-"))
            let suffix = String(name.dropFirst("session-daemon-test-".count))
            #expect(UUID(uuidString: suffix) != nil)
        }
    }

    @Test("V11: test() creates no directory")
    func testV11_noDirectoryCreated() {
        let fresh = SessionDaemonConfiguration.test().supportDirectory
        #expect(!FileManager.default.fileExists(atPath: fresh.path))
        let missing = FileManager.default.temporaryDirectory
            .appendingPathComponent("sdc-missing-\(UUID().uuidString)")
        let config = SessionDaemonConfiguration.test(root: missing)
        #expect(!FileManager.default.fileExists(atPath: config.supportDirectory.path))
    }

    @Test("V12: test() intervals")
    func testV12_testIntervals() {
        let config = SessionDaemonConfiguration.test()
        #expect(config.livenessCheckInterval == 1)
        #expect(config.retentionDays == 7)
        #expect(config.retentionCheckInterval == 86400)
    }

    @Test("V14: zero values are stored as given")
    func testV14_noValidation() {
        let config = makeConfiguration(httpPort: 0, retentionDays: 0)
        #expect(config.retentionDays == 0)
        #expect(config.httpPort == 0)
    }
}
