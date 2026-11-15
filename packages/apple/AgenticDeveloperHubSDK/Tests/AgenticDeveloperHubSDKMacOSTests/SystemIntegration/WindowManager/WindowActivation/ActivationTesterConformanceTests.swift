import AgenticDeveloperHubSDKCore
import AppKit
import ApplicationServices
import Foundation
import XCTest
@testable import AgenticDeveloperHubSDKMacOS

/// A strategy whose applicability and result are fixed, recording whether it was attempted.
final class ScriptedActivationStrategy: WindowActivationStrategy, @unchecked Sendable {
    let name: String
    private let applies: Bool
    private let result: Bool
    private let lock = NSLock()
    private var attempts = 0

    init(name: String, applies: Bool, result: Bool) {
        self.name = name
        self.applies = applies
        self.result = result
    }

    var attemptCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return attempts
    }

    func appliesTo(_ target: WindowActivationTarget) -> Bool { applies }

    func activate(_ target: WindowActivationTarget, log: ActivationTestLog) -> Bool {
        lock.lock()
        attempts += 1
        lock.unlock()
        return result
    }
}

/// Conformance vectors window-activation-014 ... 018 for `WindowActivationTester`.
///
/// The harness gates on the process's real Accessibility trust, which a unit test cannot change: 014 runs only
/// when the test process is not trusted, 015 ... 018 only when it is.
final class ActivationTesterConformanceTests: XCTestCase {

    private let target = WindowActivationTarget(
        identifier: "ident", projectName: "demo", cwd: "/tmp/demo", pid: 1, termProgram: "vscode"
    )

    /// Log entries with their `[timestamp] ` prefix removed.
    private func messages(_ log: ActivationTestLog) -> [String] {
        log.text.split(separator: "\n", omittingEmptySubsequences: false).dropLast().map { line in
            guard let closing = line.firstIndex(of: "]") else { return String(line) }
            return String(line[(line.index(closing, offsetBy: 2, limitedBy: line.endIndex) ?? line.endIndex)...])
        }
    }

    private func makeTester(
        targets: [WindowActivationTarget],
        strategies: [WindowActivationStrategy],
        log: ActivationTestLog
    ) -> WindowActivationTester {
        _ = NSApplication.shared
        return WindowActivationTester(
            targets: targets, log: log, strategies: strategies, runningApps: EmptyRunningAppsProvider()
        )
    }

    func testV014_permissionDeniedAborts() throws {
        try XCTSkipIf(AXIsProcessTrusted(), "test process is Accessibility-trusted; abort path unreachable")
        let log = ActivationTestLog(fileURL: nil)
        let tester = makeTester(targets: [target], strategies: [], log: log)

        let outcome = tester.runAllTests()

        XCTAssertEqual(outcome.passed, 0)
        XCTAssertEqual(outcome.failed, 0)
        XCTAssertEqual(messages(log), [
            "=== Window Activation Test Harness ===",
            "Accessibility: DENIED",
            "ABORT: Accessibility permission required"
        ])
    }

    func testV015_cascadeStopsAfterFirstSuccess() throws {
        try XCTSkipUnless(AXIsProcessTrusted(), "needs Accessibility trust for the test process")
        let first = ScriptedActivationStrategy(name: "S1", applies: true, result: true)
        let second = ScriptedActivationStrategy(name: "S2", applies: true, result: true)
        let third = ScriptedActivationStrategy(name: "S3", applies: false, result: true)
        let log = ActivationTestLog(fileURL: nil)

        makeTester(targets: [target], strategies: [first, second, third], log: log).runAllTests()

        let lines = messages(log)
        XCTAssertTrue(lines.contains("  Strategy S1: SUCCESS"))
        XCTAssertTrue(lines.contains("  Strategy S2: skipped (already activated)"))
        XCTAssertTrue(lines.contains("  Strategy S3: skipped (already activated)"))
        XCTAssertEqual(first.attemptCount, 1)
        XCTAssertEqual(second.attemptCount, 0)
        XCTAssertEqual(third.attemptCount, 0)
    }

    func testV016_notApplicableThenFailedStrategy() throws {
        try XCTSkipUnless(AXIsProcessTrusted(), "needs Accessibility trust for the test process")
        let first = ScriptedActivationStrategy(name: "S1", applies: false, result: true)
        let second = ScriptedActivationStrategy(name: "S2", applies: true, result: false)
        let log = ActivationTestLog(fileURL: nil)

        makeTester(targets: [target], strategies: [first, second], log: log).runAllTests()

        let lines = messages(log)
        let skipped = try XCTUnwrap(lines.firstIndex(of: "  Strategy S1: skipped (not applicable)"))
        let failed = try XCTUnwrap(lines.firstIndex(of: "  Strategy S2: FAILED"))
        XCTAssertLessThan(skipped, failed)
        XCTAssertEqual(first.attemptCount, 0)
        XCTAssertEqual(second.attemptCount, 1)
    }

    func testV017_noFrontmostApplicationFailsTarget() throws {
        try XCTSkipUnless(AXIsProcessTrusted(), "needs Accessibility trust for the test process")
        let log = ActivationTestLog(fileURL: nil)

        let outcome = makeTester(targets: [target], strategies: [], log: log).runAllTests()

        let lines = messages(log)
        XCTAssertTrue(lines.contains("  After activation: frontmost=\"\""))
        XCTAssertTrue(lines.contains("  Result: FAIL"))
        XCTAssertEqual(outcome.passed, 0)
        XCTAssertEqual(outcome.failed, 1)
    }

    func testV018_emptyTargetListReportsZeroResults() throws {
        try XCTSkipUnless(AXIsProcessTrusted(), "needs Accessibility trust for the test process")
        let log = ActivationTestLog(fileURL: nil)

        let outcome = makeTester(targets: [], strategies: [], log: log).runAllTests()

        XCTAssertEqual(outcome.passed, 0)
        XCTAssertEqual(outcome.failed, 0)
        XCTAssertEqual(messages(log).last, "=== Results: 0 passed, 0 failed ===")
    }
}
