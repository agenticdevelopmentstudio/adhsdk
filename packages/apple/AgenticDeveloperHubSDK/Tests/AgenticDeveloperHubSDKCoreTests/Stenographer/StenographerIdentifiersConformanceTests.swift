import XCTest
@testable import AgenticDeveloperHubSDKCore

final class StenographerIdentifiersConformanceTests: XCTestCase {
    private let home = URL(fileURLWithPath: "/h", isDirectory: true)
    private let current = "/h/Library/Application Support/com.agenticdevelopmentstudio.stenographer"
    private let legacy = "/h/Library/Application Support/com.agentic-cookbook.stenographer"
    private let currentLogs = "/h/Library/Logs/com.agenticdevelopmentstudio.stenographer"
    private let legacyLogs = "/h/Library/Logs/com.agentic-cookbook.stenographer"

    private func paths(existing: Set<String>) -> StenographerPaths {
        StenographerPaths(home: home, exists: { existing.contains($0.path) })
    }

    func testV1_httpPortAndBaseURL() {
        XCTAssertEqual(StenographerIdentifiers.httpPort, 22847)
        XCTAssertEqual(StenographerIdentifiers.httpBaseURL, "http://127.0.0.1:22847")
    }

    func testV2_routerPortDiffersFromHTTPPort() {
        XCTAssertEqual(StenographerIdentifiers.routerPort, 22848)
        XCTAssertEqual(StenographerIdentifiers.routerBaseURL, "http://127.0.0.1:22848")
        XCTAssertNotEqual(StenographerIdentifiers.routerPort, StenographerIdentifiers.httpPort)
    }

    func testV3_labelAndKeychainServices() {
        XCTAssertEqual(StenographerIdentifiers.label, "com.agenticdevelopmentstudio.stenographer")
        XCTAssertEqual(
            StenographerIdentifiers.daemonKeychainService, "com.agenticdevelopmentstudio.stenographer.daemon")
        XCTAssertEqual(
            StenographerIdentifiers.legacyDaemonKeychainService, "com.agentic-cookbook.stenographer.daemon")
    }

    func testV4_subsystemSuffix() {
        XCTAssertEqual(StenographerIdentifiers.subsystem("db"), "com.agenticdevelopmentstudio.stenographer.db")
        XCTAssertEqual(StenographerIdentifiers.subsystem(""), StenographerIdentifiers.label + ".")
    }

    func testV5_currentDirectoryWinsOnceItHoldsTheDatabase() {
        let resolved = paths(existing: [current + "/stenographer.db", current, legacy]).supportDirectory
        XCTAssertEqual(resolved.path, current)
    }

    func testV6_emptyCurrentDirectoryDoesNotHideLegacy() {
        let resolved = paths(existing: [legacy, current]).supportDirectory
        XCTAssertEqual(resolved.path, legacy)
    }

    func testV7_freshInstallUsesCurrentDirectories() {
        let fresh = paths(existing: [])
        XCTAssertEqual(fresh.supportDirectory.path, current)
        XCTAssertEqual(fresh.logsDirectory.path, currentLogs)
    }

    func testV8_pluginDirectoriesAreCurrentThenLegacy() {
        let urls = paths(existing: []).pluginDirectories
        XCTAssertEqual(urls.map(\.path), [current + "/Plugins", legacy + "/Plugins"])
    }

    func testV9_writeFollowsTheDirectoryWhenItMoves() throws {
        let migrated = IdentifiersCallCounter()
        let dbPath = current + "/stenographer.db"
        let legacyPath = legacy
        let subject = StenographerPaths(home: home, exists: { url in
            if url.path == dbPath { return migrated.value > 0 }
            return url.path == legacyPath
        })
        var written: [String] = []
        let result = subject.writeSupportFile(named: "f.txt") { url in
            written.append(url.path)
            migrated.bump()
        }
        XCTAssertEqual(written, [legacy + "/f.txt", current + "/f.txt"])
        XCTAssertEqual(result.path, current + "/f.txt")
    }

    func testV10_zeroAttemptsStillWritesOnceAndReturnsTheResolvedURL() {
        let subject = alternatingPaths()
        var written: [String] = []
        let result = subject.writeSupportFile(named: "f.txt", attempts: 0) { written.append($0.path) }
        XCTAssertEqual(written, [legacy + "/f.txt"])
        XCTAssertEqual(result.path, current + "/f.txt")
        XCTAssertFalse(written.contains(result.path))
    }

    func testV11_aThrowingWriteIsPropagatedAfterOneRun() {
        struct Boom: Error {}
        var runs = 0
        XCTAssertThrowsError(try paths(existing: []).writeSupportFile(named: "f.txt") { _ in
            runs += 1
            throw Boom()
        }) { error in
            XCTAssertTrue(error is Boom)
        }
        XCTAssertEqual(runs, 1)
    }

    func testV12_launchAgentPlists() {
        let subject = paths(existing: [])
        XCTAssertEqual(
            subject.launchAgentPlist.path, "/h/Library/LaunchAgents/com.agenticdevelopmentstudio.stenographer.plist")
        XCTAssertEqual(
            subject.legacyLaunchAgentPlist.path, "/h/Library/LaunchAgents/com.agentic-cookbook.stenographer.plist")
        XCTAssertEqual(
            subject.legacyMenubarLaunchAgentPlist.path,
            "/h/Library/LaunchAgents/com.agentic-cookbook.stenographer.menubar.plist")
    }

    func testV13_nothingCollidesWithTheKitchenDaemon() {
        let steno = StenographerPaths(home: home, exists: { _ in false })
        let kitchen = ADKDPaths(home: home)
        XCTAssertNotEqual(ADKDIdentifiers.label, StenographerIdentifiers.label)
        XCTAssertNotEqual(ADKDIdentifiers.httpPort, StenographerIdentifiers.httpPort)
        XCTAssertNotEqual(ADKDIdentifiers.keychainService, StenographerIdentifiers.daemonKeychainService)
        XCTAssertNotEqual(ADKDPaths.databaseFileName, StenographerPaths.databaseFileName)
        XCTAssertNotEqual(kitchen.supportDirectory, steno.supportDirectory)
        XCTAssertNotEqual(kitchen.logsDirectory, steno.logsDirectory)
        XCTAssertNotEqual(kitchen.launchAgentPlist, steno.launchAgentPlist)
    }

    func testV14_threeAttemptsReturnTheLastResolvedURLNotTheLastWritten() {
        let subject = alternatingPaths()
        var written: [String] = []
        let result = subject.writeSupportFile(named: "f.txt", attempts: 3) { written.append($0.path) }
        XCTAssertEqual(written, [legacy + "/f.txt", current + "/f.txt", legacy + "/f.txt"])
        XCTAssertEqual(result.path, current + "/f.txt")
    }

    func testV15_legacyLabels() {
        XCTAssertEqual(StenographerIdentifiers.legacyLabel, "com.agentic-cookbook.stenographer")
        XCTAssertEqual(StenographerIdentifiers.legacyMenubarLabel, "com.agentic-cookbook.stenographer.menubar")
    }

    func testV16_subsystemIsTheLabel() {
        XCTAssertEqual(StenographerIdentifiers.subsystem, StenographerIdentifiers.label)
    }

    func testV17_homeIsInjectedOrTheCurrentUsers() {
        let injected = StenographerPaths(home: home, exists: { _ in false })
        XCTAssertEqual(injected.currentSupportDirectory.path, current)
        let derived = StenographerPaths()
        let userHome = FileManager.default.homeDirectoryForCurrentUser.path
        XCTAssertTrue(derived.currentSupportDirectory.path.hasPrefix(userHome))
        XCTAssertTrue(derived.currentSupportDirectory.path.hasSuffix(
            "Library/Application Support/com.agenticdevelopmentstudio.stenographer"))
    }

    func testV18_supportDirectories() {
        let subject = StenographerPaths(home: home, exists: { _ in false })
        XCTAssertEqual(subject.currentSupportDirectory.path, current)
        XCTAssertEqual(subject.legacySupportDirectory.path, legacy)
    }

    func testV19_existenceIsOnlyConsultedForTheResolvedDirectories() {
        let calls = IdentifiersCallCounter()
        let subject = StenographerPaths(home: home, exists: { _ in calls.bump(); return false })
        _ = subject.launchAgentPlist
        _ = subject.pluginDirectories
        XCTAssertEqual(calls.value, 0)
        _ = subject.supportDirectory
        XCTAssertGreaterThan(calls.value, 0)
        let afterSupport = calls.value
        _ = subject.logsDirectory
        XCTAssertGreaterThan(calls.value, afterSupport)
    }

    func testV20_legacyLogsDirectoryIsUsedWhenOnlyItExists() {
        XCTAssertEqual(paths(existing: [legacyLogs]).logsDirectory.path, legacyLogs)
    }

    func testV21_currentLogsDirectoryWinsWithoutASentinel() {
        XCTAssertEqual(paths(existing: [currentLogs, legacyLogs]).logsDirectory.path, currentLogs)
    }

    /// The support directory alternates between legacy and current on every resolution.
    private func alternatingPaths() -> StenographerPaths {
        let resolutions = IdentifiersCallCounter()
        let dbPath = current + "/stenographer.db"
        let legacyPath = legacy
        return StenographerPaths(home: home, exists: { url in
            if url.path == dbPath {
                resolutions.bump()
                return resolutions.value % 2 == 0
            }
            return url.path == legacyPath
        })
    }
}

final class IdentifiersCallCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0
    var value: Int { lock.withLock { count } }
    func bump() { lock.withLock { count += 1 } }
}
