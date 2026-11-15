import XCTest
@testable import AgenticDeveloperHubSDKCore

/// Conformance vectors for the two plain-data types in `BillingAppSpans.swift`.
final class BillingAppSpansTests: XCTestCase {

    private func row(
        id: String = "S", bundleId: String = "com.example.app", appName: String = "App",
        windowTitle: String = "Title", workingPath: String = "/w", repoRoot: String = "/r",
        branch: String = "main", startedAt: String = "2026-10-01T09:00:00Z",
        endedAt: String = "2026-10-01T10:00:00Z", tz tzName: String = "UTC"
    ) -> BillingAppSpanRow {
        BillingAppSpanRow(
            id: id, bundleId: bundleId, appName: appName, windowTitle: windowTitle,
            workingPath: workingPath, repoRoot: repoRoot, branch: branch,
            startedAt: startedAt, endedAt: endedAt, tz: tzName
        )
    }

    func testV001_sessionIdRoundTripsThroughActivitySpanSession() {
        let value = row(id: "X1")
        XCTAssertEqual(value.sessionId, ActivitySpanSession.sessionId(spanId: "X1"))
        XCTAssertEqual(ActivitySpanSession.spanId(sessionId: value.sessionId), "X1")
    }

    func testV002_sessionIdIsAppPrefixedSpanId() {
        XCTAssertEqual(row(id: "S").sessionId, "app:S")
    }

    func testV003_emptyEndedAtReadsBackEmpty() {
        XCTAssertEqual(row(endedAt: "").endedAt, "")
    }

    func testV004_idleIntervalKeepsItsStringsIncludingOpenUntil() {
        let interval = BillingIdleInterval(idleFrom: "2026-10-01T09:20:00Z", idleUntil: "")
        XCTAssertEqual(interval.idleFrom, "2026-10-01T09:20:00Z")
        XCTAssertEqual(interval.idleUntil, "")
    }

    func testV005_equalByFieldValueAndEveryFieldCounts() {
        XCTAssertEqual(row(), row())
        XCTAssertNotEqual(row(), row(id: "T"))
        XCTAssertNotEqual(row(), row(bundleId: "other"))
        XCTAssertNotEqual(row(), row(appName: "Other"))
        XCTAssertNotEqual(row(), row(windowTitle: "Other"))
        XCTAssertNotEqual(row(), row(workingPath: "/x"))
        XCTAssertNotEqual(row(), row(repoRoot: "/x"))
        XCTAssertNotEqual(row(), row(branch: "dev"))
        XCTAssertNotEqual(row(), row(startedAt: "2026-10-01T09:00:01Z"))
        XCTAssertNotEqual(row(), row(endedAt: ""))
        XCTAssertNotEqual(row(), row(tz: "Europe/Paris"))
        XCTAssertEqual(
            BillingIdleInterval(idleFrom: "a", idleUntil: "b"), BillingIdleInterval(idleFrom: "a", idleUntil: "b"))
        XCTAssertNotEqual(
            BillingIdleInterval(idleFrom: "a", idleUntil: "b"), BillingIdleInterval(idleFrom: "a", idleUntil: "c"))
        XCTAssertNotEqual(
            BillingIdleInterval(idleFrom: "a", idleUntil: "b"), BillingIdleInterval(idleFrom: "z", idleUntil: "b"))
    }

    func testV006_noValidationOfTimestamps() {
        XCTAssertEqual(row(startedAt: "not-a-date").startedAt, "not-a-date")
    }

    func testV007_unresolvedPathAndNoRepoReadBackEmpty() {
        let value = row(workingPath: "", repoRoot: "")
        XCTAssertEqual(value.workingPath, "")
        XCTAssertEqual(value.repoRoot, "")
    }
}
