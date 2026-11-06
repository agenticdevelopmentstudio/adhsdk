import XCTest
@testable import AgenticDeveloperHubSDKNotifications

final class NoticeCodingTests: XCTestCase {

    private func decode(_ json: String) throws -> Notice {
        try NoticeCoding.decoder.decode(Notice.self, from: Data(json.utf8))
    }

    func testLegacyPayloadDecodes() throws {
        let notice = try decode(#"{"source":"ci","title":"t","body":"b"}"#)
        XCTAssertEqual(notice.urgency, .fyi)
        XCTAssertEqual(notice.body, "b")
        XCTAssertEqual(notice.actions, [])
        XCTAssertEqual(notice.state, .unread)
        XCTAssertEqual(notice.level, .info)
        XCTAssertFalse(notice.id.isEmpty)
        XCTAssertEqual(notice.timestamp.timeIntervalSinceNow, 0, accuracy: 5)
    }

    func testDecodeRejectsMissingTitle() {
        XCTAssertThrowsError(try decode(#"{"source":"ci"}"#))
    }

    func testDecodeKeepsClientSuppliedIdentityAndTimestamp() throws {
        let notice = try decode(
            #"{"id":"fixed","timestamp":"2026-01-02T03:04:05Z","source":"s","title":"t","level":"warning"}"#
        )
        XCTAssertEqual(notice.id, "fixed")
        XCTAssertEqual(notice.level, .warning)
        XCTAssertEqual(ISO8601DateFormatter().string(from: notice.timestamp), "2026-01-02T03:04:05Z")
    }

    func testStateSurvivesARoundTrip() throws {
        let moment = Date(timeIntervalSince1970: 1_757_000_000)
        let notice = Notice(source: "ci", title: "t", state: .acted, stateAt: moment)
        let decoded = try NoticeCoding.decoder.decode(Notice.self, from: NoticeCoding.encoder.encode(notice))
        XCTAssertEqual(decoded.state, .acted)
        XCTAssertEqual(decoded.stateAt, moment)
    }

    func testLifecycleAndUrgencyRawValuesAreTheWireStrings() {
        XCTAssertEqual(
            Set(Notice.Lifecycle.allCases.map(\.rawValue)),
            ["unread", "read", "acted", "dismissed", "snoozed", "archived", "expired"]
        )
        XCTAssertEqual(
            Set(Notice.Urgency.allCases.map(\.rawValue)),
            ["fyi", "eventually", "soon", "now", "emergency"]
        )
        XCTAssertEqual(Notice.Urgency.allCases.map(\.rank).sorted(), [0, 1, 2, 3, 4])
    }

    func testLifecycleActiveAndConsumed() {
        for state in Notice.Lifecycle.allCases {
            XCTAssertEqual(state.isActive, state == .unread)
            XCTAssertEqual(state.isConsumed, [.acted, .archived, .dismissed, .expired].contains(state))
        }
    }

    func testDetailsAliasesBody() throws {
        let notice = try decode(#"{"source":"s","title":"t","details":"d"}"#)
        XCTAssertEqual(notice.body, "d")
        let encoded = try XCTUnwrap(String(data: NoticeCoding.encoder.encode(notice), encoding: .utf8))
        XCTAssertTrue(encoded.contains(#""body":"d""#))
        XCTAssertFalse(encoded.contains("details"))
    }

    func testBodyWinsOverDetails() throws {
        let notice = try decode(#"{"source":"s","title":"t","body":"b","details":"d"}"#)
        XCTAssertEqual(notice.body, "b")
    }

    func testTTLResolvesAgainstTimestamp() throws {
        let notice = try decode(#"{"source":"s","title":"t","timestamp":"2026-01-01T00:00:00Z","ttl":60}"#)
        XCTAssertEqual(notice.expiresAt, ISO8601DateFormatter().date(from: "2026-01-01T00:01:00Z"))

        let explicit = try decode(
            #"{"source":"s","title":"t","timestamp":"2026-01-01T00:00:00Z","ttl":60,"#
                + #""expiresAt":"2026-02-01T00:00:00Z"}"#
        )
        XCTAssertEqual(explicit.expiresAt, ISO8601DateFormatter().date(from: "2026-02-01T00:00:00Z"))
    }

    func testUnknownUrgencyThrows() {
        XCTAssertThrowsError(try decode(#"{"source":"s","title":"t","urgency":"whenever"}"#)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testActionKindsRoundTrip() throws {
        let json = #"""
        {"source":"s","title":"t","timestamp":"2026-01-01T00:00:00Z","actions":[
          {"id":"pr","label":"Open PR","url":"https://example.com/pr/1"},
          {"id":"approve","label":"Approve"},
          {"id":"reply","label":"Reply","reply":true,"placeholder":"Say something"}
        ]}
        """#
        let first = try decode(json)
        XCTAssertEqual(first.actions.map(\.id), ["pr", "approve", "reply"])
        XCTAssertEqual(first.actions[0].kind, .open(URL(string: "https://example.com/pr/1")!))
        XCTAssertEqual(first.actions[1].kind, .callback)
        XCTAssertEqual(first.actions[2].kind, .reply(placeholder: "Say something"))
        XCTAssertEqual(first.primaryAction?.id, "pr")

        let second = try NoticeCoding.decoder.decode(Notice.self, from: NoticeCoding.encoder.encode(first))
        XCTAssertEqual(second, first)
    }

    func testReplyWithoutPlaceholderRoundTrips() throws {
        let notice = try decode(
            #"{"source":"s","title":"t","timestamp":"2026-01-01T00:00:00Z","#
                + #""actions":[{"id":"r","label":"R","reply":true}]}"#
        )
        XCTAssertEqual(notice.actions[0].kind, .reply(placeholder: nil))
        let again = try NoticeCoding.decoder.decode(Notice.self, from: NoticeCoding.encoder.encode(notice))
        XCTAssertEqual(again, notice)
    }

    func testMalformedActionThrows() {
        XCTAssertThrowsError(
            try decode(#"{"source":"s","title":"t","actions":[{"id":"a","label":"A","url":"not a url"}]}"#)
        ) { error in
            XCTAssertEqual(error as? NoticeDecodingError, .malformedAction("a"))
        }
        XCTAssertThrowsError(
            try decode(#"{"source":"s","title":"t","actions":[{"id":"a","label":"A","url":"nowhere"}]}"#)
        ) { error in
            XCTAssertEqual(error as? NoticeDecodingError, .malformedAction("a"))
        }
        XCTAssertThrowsError(try decode(#"{"source":"s","title":"t","actions":[{"id":"a"}]}"#))
    }

    func testDuplicateActionIDThrows() {
        XCTAssertThrowsError(
            try decode(#"{"source":"s","title":"t","actions":[{"id":"a","label":"A"},{"id":"a","label":"B"}]}"#)
        ) { error in
            XCTAssertEqual(error as? NoticeDecodingError, .duplicateActionID("a"))
        }
    }

    func testFullNoticeRoundTrips() throws {
        let moment = Date(timeIntervalSince1970: 1_757_000_000)
        let notice = Notice(
            id: "n1", timestamp: moment, source: "ci", title: "Build", subtitle: "sub", body: "body",
            app: "com.example.app", level: .error, urgency: .now, category: "builds",
            metadata: ["repo": "rooster"],
            actions: [
                Notice.Action(id: "o", label: "Open", kind: .open(URL(string: "https://example.com")!)),
                Notice.Action(id: "c", label: "Go", kind: .callback),
                Notice.Action(id: "r", label: "Reply", kind: .reply(placeholder: "hm"))
            ],
            expiresAt: moment.addingTimeInterval(600), key: "k", state: .snoozed,
            stateAt: moment.addingTimeInterval(1), snoozedUntil: moment.addingTimeInterval(300),
            response: NoticeResponse(actionID: "r", text: "hi", at: moment.addingTimeInterval(2))
        )
        let decoded = try NoticeCoding.decoder.decode(Notice.self, from: NoticeCoding.encoder.encode(notice))
        XCTAssertEqual(decoded, notice)
    }

    func testResponseAndStateChangeWireKeys() throws {
        let moment = Date(timeIntervalSince1970: 1_757_000_000)
        let response = try XCTUnwrap(String(
            data: NoticeCoding.encoder.encode(NoticeResponse(actionID: "a", text: nil, at: moment)),
            encoding: .utf8
        ))
        XCTAssertTrue(response.contains(#""action":"a""#))
        XCTAssertFalse(response.contains("actionID"))

        let change = NoticeStateChange(id: "n", state: .snoozed, stateAt: moment, snoozedUntil: moment)
        let decoded = try NoticeCoding.decoder.decode(
            NoticeStateChange.self, from: NoticeCoding.encoder.encode(change)
        )
        XCTAssertEqual(decoded, change)
    }
}
