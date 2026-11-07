import XCTest
@testable import AgenticDeveloperHubSDKNotifications

final class EscalationPolicyTests: XCTestCase {

    private let posted = Date(timeIntervalSince1970: 1_800_000_000)

    private func notice(_ urgency: Notice.Urgency) -> Notice {
        Notice(timestamp: posted, source: "ci", title: "t", urgency: urgency)
    }

    func testSoonEscalatesAfter15Minutes() {
        let policy = EscalationPolicy()
        let soon = notice(.soon)
        XCTAssertNil(policy.escalated(soon, now: posted.addingTimeInterval(14 * 60 + 59)))
        XCTAssertEqual(policy.escalated(soon, now: posted.addingTimeInterval(15 * 60)), .now)
        XCTAssertEqual(policy.nextCheck(for: soon), posted.addingTimeInterval(900))
    }

    func testZeroDisables() {
        let policy = EscalationPolicy(soonToNowAfter: 0, eventuallyToSoonAfter: 0)
        let late = posted.addingTimeInterval(86_400)
        XCTAssertNil(policy.escalated(notice(.soon), now: late))
        XCTAssertNil(policy.escalated(notice(.eventually), now: late))
        XCTAssertNil(policy.nextCheck(for: notice(.soon)))
        XCTAssertNil(policy.nextCheck(for: notice(.eventually)))
    }

    func testEventuallyOffByDefault() {
        let policy = EscalationPolicy()
        XCTAssertNil(policy.escalated(notice(.eventually), now: posted.addingTimeInterval(86_400)))
        XCTAssertNil(policy.nextCheck(for: notice(.eventually)))
    }

    func testEventuallyEscalatesWhenEnabled() {
        let policy = EscalationPolicy(soonToNowAfter: 900, eventuallyToSoonAfter: 600)
        let eventually = notice(.eventually)
        XCTAssertNil(policy.escalated(eventually, now: posted.addingTimeInterval(599)))
        XCTAssertEqual(policy.escalated(eventually, now: posted.addingTimeInterval(600)), .soon)
        XCTAssertEqual(policy.nextCheck(for: eventually), posted.addingTimeInterval(600))
    }

    func testOtherUrgenciesNeverEscalate() {
        let policy = EscalationPolicy()
        let late = posted.addingTimeInterval(86_400)
        for urgency in [Notice.Urgency.fyi, .now, .emergency] {
            XCTAssertNil(policy.escalated(notice(urgency), now: late))
            XCTAssertNil(policy.nextCheck(for: notice(urgency)))
        }
    }

    func testSinceMovesTheClockStartLater() {
        let policy = EscalationPolicy()
        let soon = notice(.soon)
        let shown = posted.addingTimeInterval(3600)
        XCTAssertNil(policy.escalated(soon, since: shown, now: shown.addingTimeInterval(899)))
        XCTAssertEqual(policy.escalated(soon, since: shown, now: shown.addingTimeInterval(900)), .now)
        XCTAssertEqual(policy.nextCheck(for: soon, since: shown), shown.addingTimeInterval(900))
    }

    func testSinceBeforeTheTimestampCountsFromTheTimestamp() {
        let policy = EscalationPolicy()
        let soon = notice(.soon)
        let earlier = posted.addingTimeInterval(-3600)
        XCTAssertNil(policy.escalated(soon, since: earlier, now: posted.addingTimeInterval(899)))
        XCTAssertEqual(policy.nextCheck(for: soon, since: earlier), posted.addingTimeInterval(900))
    }
}
