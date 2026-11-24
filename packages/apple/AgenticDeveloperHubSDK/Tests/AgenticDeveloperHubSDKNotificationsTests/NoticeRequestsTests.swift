import XCTest
@testable import AgenticDeveloperHubSDKNotifications

final class NoticeRequestsTests: XCTestCase {

    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func decode(_ json: String) throws -> SnoozeRequest {
        try NoticeCoding.decoder.decode(SnoozeRequest.self, from: Data(json.utf8))
    }

    func testSnoozeMinutesResolves() throws {
        let request = try decode(#"{"minutes":15}"#)
        XCTAssertEqual(request.resolvedUntil(now: now), now.addingTimeInterval(900))
    }

    func testSnoozeUntilWins() {
        let until = now.addingTimeInterval(7_200)
        let request = SnoozeRequest(until: until, minutes: 15)
        XCTAssertEqual(request.resolvedUntil(now: now), until)
    }

    func testSnoozeEmptyIsNil() throws {
        XCTAssertNil(try decode("{}").resolvedUntil(now: now))
    }

    func testSnoozeNonPositiveIsNil() {
        XCTAssertNil(SnoozeRequest(minutes: 0).resolvedUntil(now: now))
        XCTAssertNil(SnoozeRequest(minutes: -5).resolvedUntil(now: now))
    }

    func testRespondAndStateRequestsRoundTrip() throws {
        let respond = RespondRequest(action: "reply", text: "ok")
        let data = try NoticeCoding.encoder.encode(respond)
        XCTAssertEqual(try NoticeCoding.decoder.decode(RespondRequest.self, from: data), respond)

        let state = try NoticeCoding.decoder.decode(NoticeStateRequest.self, from: Data(#"{"state":"read"}"#.utf8))
        XCTAssertEqual(state, NoticeStateRequest(state: "read"))
    }
}
