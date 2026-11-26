@testable import AgenticDeveloperHubSDKCore
import Foundation
import XCTest

/// Conformance vectors for `HookDropWriter`: the override variable's name, the
/// directory choice and `writeDropFile`'s publication rules. Vector ids are in
/// the test names; drop-001, 005, 006, 007 and 016 are covered by
/// `HookCaptureTests`.
final class HookDropWriterConformanceTests: XCTestCase {

    private var directory: URL!

    override func setUpWithError() throws {
        directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("hookdrop-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func configuration(name: String) -> ClaudeHookConfiguration {
        ClaudeHookConfiguration(
            name: name,
            marker: "# \(name)-hook",
            hookBinaryPath: "/Applications/Kitchen.app/Contents/Helpers/adk",
            hookArguments: ["hook", "--event"],
            statusLineArguments: ["statusline"],
            statusLineTapOnly: true,
            dropDirectory: "~/.claude/adkd-events",
            settingsURL: directory.appendingPathComponent("settings.json"),
            ownLockName: ".adkd-hooks.lock",
            statusLineEntryName: "adkd",
            bundledDispatcher: nil,
            legacy: .none)
    }

    private func names(_ url: URL) throws -> [String] {
        try FileManager.default.contentsOfDirectory(atPath: url.path).sorted()
    }

    // MARK: - Override variable

    func testDrop002_punctuationBecomesUnderscores() {
        XCTAssertEqual(HookDropWriter.dropDirectoryVariable(configuration: configuration(name: "my-app.v2")),
                       "MY_APP_V2_DROP_DIR")
    }

    func testDrop003_aNonASCIILetterBecomesAnUnderscore() {
        XCTAssertEqual(HookDropWriter.dropDirectoryVariable(configuration: configuration(name: "caf\u{E9}")),
                       "CAF__DROP_DIR")
    }

    func testDrop004_anEmptyNameYieldsABareSuffix() {
        XCTAssertEqual(HookDropWriter.dropDirectoryVariable(configuration: configuration(name: "")),
                       "_DROP_DIR")
    }

    func testDrop008_anEmptyEnvironmentGivesTheConfiguredDirectoryUnexpanded() {
        XCTAssertEqual(HookDropWriter.dropDirectory(configuration: configuration(name: "adkd"), environment: [:]),
                       "~/.claude/adkd-events")
    }

    /// The default is this process's environment. The variable is one the
    /// process starts with — the test scheme sets
    /// `HOOKDROPCONFORMANCE_DROP_DIR` (`project.yml`) — rather than one planted
    /// with `setenv`: the process environment is one table shared with every
    /// test running beside this one, and a `setenv` reallocates it under any
    /// thread copying it to spawn a child.
    func testDrop017_theEnvironmentDefaultsToTheProcessEnvironment() throws {
        let key = "HOOKDROPCONFORMANCE_DROP_DIR"
        let value = try XCTUnwrap(ProcessInfo.processInfo.environment[key],
                                  "run under the scheme that sets \(key)")
        XCTAssertEqual(value, "/tmp/from-process-env")
        let config = configuration(name: "HOOKDROPCONFORMANCE")
        XCTAssertEqual(HookDropWriter.dropDirectoryVariable(configuration: config), key)
        XCTAssertEqual(HookDropWriter.dropDirectory(configuration: config), "/tmp/from-process-env")
        XCTAssertEqual(HookDropWriter.dropDirectory(configuration: config, environment: [key: "/tmp/given"]),
                       "/tmp/given")
    }

    // MARK: - Writing

    func testDrop009_aMissingDirectoryIsCreatedAndOneCompactJSONFileIsPublished() throws {
        let drop = directory.appendingPathComponent("a/b/drop")
        try HookDropWriter.writeDropFile(envelope: ["event": "Stop", "n": 1], directory: drop.path)

        let files = try names(drop)
        XCTAssertEqual(files.count, 1, "files: \(files)")
        let file = try XCTUnwrap(files.first)
        XCTAssertNotNil(file.range(of: #"^\d+-[0-9a-f]{8}\.json$"#, options: .regularExpression), file)
        XCTAssertFalse(files.contains { $0.hasSuffix(".tmp") })

        let text = try String(contentsOf: drop.appendingPathComponent(file), encoding: .utf8)
        XCTAssertFalse(text.contains("\n"))
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any])
        XCTAssertEqual(object["event"] as? String, "Stop")
    }

    func testDrop010_aLeadingTildeIsExpandedToTheHomeDirectory() throws {
        let unique = "hookdrop-conformance-\(UUID().uuidString)"
        let expanded = ("~/\(unique)" as NSString).expandingTildeInPath
        defer { try? FileManager.default.removeItem(atPath: expanded) }
        XCTAssertNotEqual(expanded, "~/\(unique)")

        try HookDropWriter.writeDropFile(envelope: ["event": "Stop"], directory: "~/\(unique)")

        let files = try FileManager.default.contentsOfDirectory(atPath: expanded)
        XCTAssertEqual(files.filter { $0.hasSuffix(".json") }.count, 1)
        XCTAssertFalse(FileManager.default.fileExists(atPath: FileManager.default.currentDirectoryPath
                                                        + "/~/\(unique)"))
    }

    func testDrop011_twoQuickWritesProduceTwoDistinctFiles() throws {
        let drop = directory.appendingPathComponent("drop")
        try HookDropWriter.writeDropFile(envelope: ["event": "Stop"], directory: drop.path)
        try HookDropWriter.writeDropFile(envelope: ["event": "Stop"], directory: drop.path)
        let files = try names(drop)
        XCTAssertEqual(files.count, 2)
        XCTAssertEqual(Set(files).count, 2)
    }

    func testDrop012_aDirectoryUnderARegularFileThrowsAndCreatesNothing() throws {
        let blocker = directory.appendingPathComponent("blocker")
        try Data("file".utf8).write(to: blocker)
        let drop = blocker.appendingPathComponent("sub")
        XCTAssertThrowsError(try HookDropWriter.writeDropFile(envelope: ["event": "Stop"], directory: drop.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: drop.path))
        XCTAssertEqual(try Data(contentsOf: blocker), Data("file".utf8))
    }

    func testDrop013_anExistingDirectoryIsReusedAcrossWrites() throws {
        let drop = directory.appendingPathComponent("existing")
        try FileManager.default.createDirectory(at: drop, withIntermediateDirectories: true)
        try HookDropWriter.writeDropFile(envelope: ["event": "A"], directory: drop.path)
        try HookDropWriter.writeDropFile(envelope: ["event": "B"], directory: drop.path)
        XCTAssertEqual(try names(drop).count, 2)
    }

    func testDrop014_anExistingFinalNameIsNotOverwritten() throws {
        throw XCTSkip("the file name comes from the wall clock and a random suffix, neither injectable, "
                      + "so a collision with an existing final name cannot be arranged")
    }

    func testDrop015_aScannerNeverSeesAPartialJSONFile() throws {
        throw XCTSkip("a write in progress cannot be observed deterministically from a unit test")
    }

    func testDrop018_twentyConcurrentWritesProduceTwentyDistinctFiles() throws {
        let drop = directory.appendingPathComponent("concurrent")
        let lock = NSLock()
        nonisolated(unsafe) var failures = 0
        DispatchQueue.concurrentPerform(iterations: 20) { index in
            do {
                try HookDropWriter.writeDropFile(envelope: ["event": "Stop", "index": index], directory: drop.path)
            } catch {
                lock.lock()
                failures += 1
                lock.unlock()
            }
        }
        XCTAssertEqual(failures, 0)
        let files = try names(drop).filter { $0.hasSuffix(".json") }
        XCTAssertEqual(files.count, 20)
        XCTAssertEqual(Set(files).count, 20)
    }
}
