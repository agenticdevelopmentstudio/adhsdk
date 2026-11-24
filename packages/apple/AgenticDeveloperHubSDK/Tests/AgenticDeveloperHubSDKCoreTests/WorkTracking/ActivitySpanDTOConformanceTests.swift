import XCTest
@testable import AgenticDeveloperHubSDKCore

/// Conformance vectors activity-span-dto-001 to 014.
final class ActivitySpanDTOConformanceTests: XCTestCase {

    private let started = "2026-10-01T09:00:00Z"
    private let ended = "2026-10-01T10:00:00Z"

    private func makeSpan(id: String = "s", endedAt: String = "", lastSeenAt: String = "") -> ActivitySpanDTO {
        ActivitySpanDTO(id: id, bundleId: "com.apple.dt.Xcode", appName: "Xcode", startedAt: started,
                        endedAt: endedAt, tz: "UTC", lastSeenAt: lastSeenAt)
    }

    func testV001_optionalStringsDefaultToEmpty() {
        let span = ActivitySpanDTO(bundleId: "com.apple.dt.Xcode", appName: "Xcode", startedAt: started, tz: "UTC")
        XCTAssertEqual(span.windowTitle, "")
        XCTAssertEqual(span.workingPath, "")
        XCTAssertEqual(span.repoRoot, "")
        XCTAssertEqual(span.branch, "")
        XCTAssertEqual(span.endedAt, "")
        XCTAssertEqual(span.lastSeenAt, "")
    }

    func testV002_defaultIdIsAFreshUUID() {
        let first = ActivitySpanDTO(bundleId: "b", appName: "B", startedAt: started, tz: "UTC")
        let second = ActivitySpanDTO(bundleId: "b", appName: "B", startedAt: started, tz: "UTC")
        XCTAssertNotNil(UUID(uuidString: first.id))
        XCTAssertNotNil(UUID(uuidString: second.id))
        XCTAssertNotEqual(first.id, second.id)
    }

    func testV003_explicitIdIsKept() {
        XCTAssertEqual(makeSpan(id: "s").id, "s")
    }

    func testV004_emptyEndedAtIsOpen() {
        XCTAssertTrue(makeSpan(endedAt: "").isOpen)
    }

    func testV005_nonEmptyEndedAtIsClosed() {
        XCTAssertFalse(makeSpan(endedAt: ended).isOpen)
    }

    func testV006_settingEndedAtClosesTheSpan() {
        var span = makeSpan()
        XCTAssertTrue(span.isOpen)
        span.endedAt = ended
        XCTAssertFalse(span.isOpen)
    }

    func testV007_mutableFieldsChangeAndImmutableFieldsDoNot() {
        var span = makeSpan()
        span.windowTitle = "Main.swift"
        span.lastSeenAt = ended
        XCTAssertEqual(span.windowTitle, "Main.swift")
        XCTAssertEqual(span.lastSeenAt, ended)
        XCTAssertEqual(span.id, "s")
        XCTAssertEqual(span.startedAt, started)
    }

    func testV008_statusRoundTripsSnakeCase() throws {
        // The full WorkTrackingStatus round trip is asserted by WorkTrackingModelsTests.testStatusRoundTripsSnakeCase;
        // here the span itself goes through the same strategies and keys.
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let span = makeSpan(lastSeenAt: ended)
        let data = try encoder.encode(span)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertNotNil(object["bundle_id"])
        XCTAssertNotNil(object["last_seen_at"])
        XCTAssertEqual(try decoder.decode(ActivitySpanDTO.self, from: data), span)
    }

    func testV009_isOpenIsNotEncoded() throws {
        let data = try JSONEncoder().encode(makeSpan())
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertNil(object["isOpen"])
        XCTAssertNil(object["is_open"])
    }

    func testV010_noValidation() {
        let span = ActivitySpanDTO(bundleId: "b", appName: "B", startedAt: "not a date", tz: "")
        XCTAssertEqual(span.startedAt, "not a date")
        XCTAssertEqual(span.tz, "")
    }

    func testV011_copiesAreIndependent() {
        let original = makeSpan()
        var copy = original
        copy.endedAt = ended
        XCTAssertTrue(original.isOpen)
        XCTAssertFalse(copy.isOpen)
    }

    func testV012_equalityComparesEveryField() {
        XCTAssertEqual(makeSpan(), makeSpan())
        XCTAssertNotEqual(makeSpan(lastSeenAt: ""), makeSpan(lastSeenAt: ended))
    }

    func testV013_sentinelsAreEmptyStringsByDefault() {
        let span = makeSpan()
        XCTAssertEqual(span.workingPath, "")
        XCTAssertEqual(span.repoRoot, "")
        XCTAssertEqual(span.lastSeenAt, "")
    }

    func testV014_everyEncodedValueIsAString() throws {
        let data = try JSONEncoder().encode(makeSpan(endedAt: ended, lastSeenAt: ended))
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertFalse(object.isEmpty)
        for (key, value) in object {
            XCTAssertTrue(value is String, "\(key) is not a string")
        }
    }
}
