import XCTest
@testable import AgenticDeveloperHubSDKCore

final class ADKDIdentifiersTests: XCTestCase {
    private let home = URL(fileURLWithPath: "/tmp/adkd-home", isDirectory: true)
    private var paths: ADKDPaths { ADKDPaths(home: home) }

    func testEveryPathIsTheExpectedAbsolutePath() {
        XCTAssertEqual(paths.storageDirectory.path, "/tmp/adkd-home/.agenticdeveloperkitchen")
        XCTAssertEqual(paths.supportDirectory.path, "/tmp/adkd-home/.agenticdeveloperkitchen/adkd")
        XCTAssertEqual(paths.databaseURL.path, "/tmp/adkd-home/.agenticdeveloperkitchen/adkd/adkd.db")
        XCTAssertEqual(paths.spoolURL.path, "/tmp/adkd-home/.agenticdeveloperkitchen/adkd/ingest.db")
        XCTAssertEqual(paths.errorsDirectory.path, "/tmp/adkd-home/.agenticdeveloperkitchen/adkd/errors")
        XCTAssertEqual(
            paths.pluginDirectories.map(\.path),
            ["/tmp/adkd-home/Library/Application Support/Agentic Developer Kitchen/Plugins"])
        XCTAssertEqual(paths.claudeDirectory.path, "/tmp/adkd-home/.claude")
        XCTAssertEqual(paths.dropDirectory.path, "/tmp/adkd-home/.claude/adkd-events")
        XCTAssertEqual(paths.socketURL.path, "/tmp/adkd-home/.claude/adkd.sock")
        XCTAssertEqual(
            paths.logsDirectory.path, "/tmp/adkd-home/Library/Logs/com.agenticdevelopmentstudio.adkd")
        XCTAssertEqual(
            paths.launchAgentPlist.path,
            "/tmp/adkd-home/Library/LaunchAgents/com.agenticdevelopmentstudio.adkd.plist")
        XCTAssertEqual(
            paths.stopMarkerURL.path, "/tmp/adkd-home/.agenticdeveloperkitchen/adkd/daemon-stopped-by-user")
    }

    func testTheStorageDirectoryIsTheDotLowercasedToken() {
        XCTAssertEqual(paths.storageDirectory.lastPathComponent, "." + ADKDPaths.storageToken.lowercased())
    }

    func testTheBaseURLIsBuiltFromThePort() {
        XCTAssertEqual(ADKDIdentifiers.httpPort, 22849)
        XCTAssertEqual(ADKDIdentifiers.httpBaseURL, "http://127.0.0.1:22849")
        XCTAssertTrue(ADKDIdentifiers.httpBaseURL.contains(String(ADKDIdentifiers.httpPort)))
    }

    func testTheNamesAreFixed() {
        XCTAssertEqual(ADKDIdentifiers.label, "com.agenticdevelopmentstudio.adkd")
        XCTAssertEqual(ADKDIdentifiers.subsystem("db"), "com.agenticdevelopmentstudio.adkd.db")
        XCTAssertEqual(ADKDIdentifiers.keychainService, "com.agenticdevelopmentstudio.adkd.daemon")
        XCTAssertEqual(ADKDIdentifiers.hookMarker, "# adkd-hook")
        XCTAssertEqual(ADKDIdentifiers.ownHookLockName, ".adkd-hooks.lock")
        XCTAssertEqual(ADKDIdentifiers.cliName, "adk")
        XCTAssertEqual(ADKDIdentifiers.daemonExecutableName, "adkd")
    }

    /// Both daemons run on one machine, so nothing they own may collide.
    func testNothingCollidesWithStenographer() {
        let steno = StenographerPaths(home: home, exists: { _ in false })
        XCTAssertNotEqual(ADKDIdentifiers.label, StenographerIdentifiers.label)
        XCTAssertNotEqual(ADKDIdentifiers.httpPort, StenographerIdentifiers.httpPort)
        XCTAssertNotEqual(ADKDIdentifiers.keychainService, StenographerIdentifiers.daemonKeychainService)
        XCTAssertNotEqual(ADKDIdentifiers.hookMarker, "# stenographer-hook")
        XCTAssertNotEqual(ADKDPaths.databaseFileName, StenographerPaths.databaseFileName)
        XCTAssertNotEqual(paths.supportDirectory, steno.supportDirectory)
        XCTAssertNotEqual(paths.logsDirectory, steno.logsDirectory)
        XCTAssertNotEqual(paths.launchAgentPlist, steno.launchAgentPlist)
        XCTAssertNotEqual(paths.dropDirectory.lastPathComponent, "stenographer-events")
        XCTAssertNotEqual(paths.socketURL.lastPathComponent, "stenographer.sock")
        XCTAssertNotEqual(ADKDIdentifiers.ownHookLockName, ".stenographer-hooks.lock")
    }

    func testV9_anEmptySuffixLeavesATrailingDot() {
        XCTAssertEqual(ADKDIdentifiers.subsystem(""), "com.agenticdevelopmentstudio.adkd.")
    }

    func testV10_aMissingHomeStillYieldsEveryPathAndCreatesNothing() {
        let missing = FileManager.default.temporaryDirectory
            .appendingPathComponent("adkd-missing-\(UUID().uuidString)", isDirectory: true)
        let derived = ADKDPaths(home: missing)
        let urls: [URL] = [
            derived.storageDirectory, derived.supportDirectory, derived.databaseURL, derived.spoolURL,
            derived.errorsDirectory, derived.claudeDirectory, derived.dropDirectory, derived.socketURL,
            derived.logsDirectory, derived.launchAgentPlist, derived.stopMarkerURL
        ] + derived.pluginDirectories
        for url in urls {
            XCTAssertTrue(url.path.hasPrefix(missing.path))
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: missing.path))
    }

    func testV11_theSubsystemPropertyIsTheLabelAndTheHookNameIsAdkd() {
        let subsystem: String = ADKDIdentifiers.subsystem
        XCTAssertEqual(subsystem, "com.agenticdevelopmentstudio.adkd")
        XCTAssertEqual(ADKDIdentifiers.hookName, "adkd")
    }

    func testV12_theDisplayNameAndStorageTokenAreSpelledOut() {
        XCTAssertEqual(ADKDPaths.displayName, "Agentic Developer Kitchen")
        XCTAssertEqual(ADKDPaths.storageToken, "AgenticDeveloperKitchen")
    }

    func testV13_theLaunchdLogFileNamesAreFixed() {
        XCTAssertEqual(ADKDPaths.launchdStdoutLogName, "stdout.log")
        XCTAssertEqual(ADKDPaths.launchdStderrLogName, "stderr.log")
    }
}
