import AgenticDeveloperHubSDKCore
import AppKit
import Foundation
import XCTest
@testable import AgenticDeveloperHubSDKMacOS

/// A running-applications provider that reports no applications at all.
struct EmptyRunningAppsProvider: RunningAppsProvider {
    var runningApplications: [NSRunningApplication] { [] }
    func runningApplications(withBundleIdentifier bundleID: String) -> [NSRunningApplication] { [] }
    var frontmostApplication: NSRunningApplication? { nil }
}

/// Conformance vectors window-activation-001 ... 009 (catalog, applicability and no-op activation paths).
final class ActivationStrategyConformanceTests: XCTestCase {

    private func makeTarget(
        projectName: String = "demo",
        pid: Int32 = 1,
        termProgram: String = ""
    ) -> WindowActivationTarget {
        WindowActivationTarget(
            identifier: "id", projectName: projectName, cwd: "/tmp/demo", pid: pid, termProgram: termProgram
        )
    }

    func testV001_catalogMatchesWarp() {
        let match = KnownTerminals.match(termProgram: "WarpTerminal")
        XCTAssertEqual(match?.bundleID, "dev.warp.Warp-Stable")
        XCTAssertEqual(match?.displayName, "Warp")
    }

    func testV002_catalogMatchIsCaseSensitive() {
        XCTAssertNil(KnownTerminals.match(termProgram: "iterm.app"))
    }

    func testV003_customCatalogMatch() {
        let custom = KnownTerminal(displayName: "Foo", bundleID: "x.foo", termProgramValues: ["Foo"])
        XCTAssertEqual(KnownTerminals.match(termProgram: "Foo", in: [custom]), custom)
        XCTAssertNil(KnownTerminals.match(termProgram: "Foo"))
    }

    func testV004_iTermStrategyApplicability() {
        let strategy = ITermTTYStrategy()
        XCTAssertTrue(strategy.appliesTo(makeTarget(termProgram: "")))
        XCTAssertTrue(strategy.appliesTo(makeTarget(termProgram: "iTerm.app")))
        XCTAssertFalse(strategy.appliesTo(makeTarget(termProgram: "Apple_Terminal")))
    }

    func testV005_axStrategyApplicability() {
        let strategy = AXTitleMatchStrategy(runningApps: EmptyRunningAppsProvider())
        XCTAssertFalse(strategy.appliesTo(makeTarget(projectName: "Unknown")))
        XCTAssertTrue(strategy.appliesTo(makeTarget(projectName: "unknown")))
        XCTAssertTrue(strategy.appliesTo(makeTarget(projectName: "")))
    }

    func testV006_bringToFrontApplicabilityAndDefaultCatalog() {
        let strategy = BringTerminalToFrontStrategy(runningApps: EmptyRunningAppsProvider())
        XCTAssertTrue(strategy.appliesTo(makeTarget(termProgram: "vscode")))
        XCTAssertFalse(strategy.appliesTo(makeTarget(termProgram: "")))

        let custom = KnownTerminal(displayName: "Foo", bundleID: "x.foo", termProgramValues: ["Foo"])
        let customStrategy = BringTerminalToFrontStrategy(catalog: [custom], runningApps: EmptyRunningAppsProvider())
        XCTAssertTrue(customStrategy.appliesTo(makeTarget(termProgram: "Foo")))
        XCTAssertFalse(customStrategy.appliesTo(makeTarget(termProgram: "vscode")))
    }

    func testV007_bringToFrontReturnsFalseWhenTerminalNotRunning() {
        let strategy = BringTerminalToFrontStrategy(runningApps: EmptyRunningAppsProvider())
        let log = ActivationTestLog(fileURL: nil)

        XCTAssertFalse(strategy.activate(makeTarget(termProgram: "Apple_Terminal"), log: log))
        XCTAssertEqual(log.text, "")
    }

    func testV008_axStrategyReturnsFalseWithoutMatch() {
        let strategy = AXTitleMatchStrategy(runningApps: EmptyRunningAppsProvider())
        let log = ActivationTestLog(fileURL: nil)

        XCTAssertFalse(strategy.activate(makeTarget(projectName: "demo"), log: log))
        XCTAssertEqual(log.text, "")
    }

    func testV009_iTermStrategyLogsMissingTTYForPidZero() throws {
        let log = ActivationTestLog(fileURL: nil)

        XCTAssertFalse(ITermTTYStrategy().activate(makeTarget(pid: 0, termProgram: "iTerm.app"), log: log))

        let lines = log.text.split(separator: "\n")
        XCTAssertEqual(lines.count, 1)
        XCTAssertTrue(try XCTUnwrap(lines.first).hasSuffix("  iTerm TTY: pid 0 has no TTY"))
    }
}
