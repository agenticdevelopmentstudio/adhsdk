import XCTest
@testable import AgenticDeveloperHubSDKCore

final class SummarizeReplyDTOTests: XCTestCase {

    func testV1_successShape() {
        let reply = SummarizeReplyDTO(sessionId: "s1", summary: "Fixed the bug")
        XCTAssertEqual(reply.sessionId, "s1")
        XCTAssertEqual(reply.summary, "Fixed the bug")
        XCTAssertNil(reply.error)
    }

    func testV2_failureShape() {
        let reply = SummarizeReplyDTO(sessionId: "s1", error: "model too large")
        XCTAssertNil(reply.summary)
        XCTAssertEqual(reply.error, "model too large")
    }

    func testV3_bareInitializerLeavesBothNil() {
        let reply = SummarizeReplyDTO(sessionId: "s1")
        XCTAssertNil(reply.summary)
        XCTAssertNil(reply.error)
    }

    func testV4_equatableComparesEveryField() {
        let base = SummarizeReplyDTO(sessionId: "s1", summary: "x", error: "y")
        XCTAssertEqual(base, SummarizeReplyDTO(sessionId: "s1", summary: "x", error: "y"))
        XCTAssertNotEqual(base, SummarizeReplyDTO(sessionId: "s2", summary: "x", error: "y"))
        XCTAssertNotEqual(base, SummarizeReplyDTO(sessionId: "s1", summary: "z", error: "y"))
        XCTAssertNotEqual(base, SummarizeReplyDTO(sessionId: "s1", summary: "x", error: "z"))
    }

    func testV5_defaultEncoderUsesPropertyNamesAndOmitsNilError() throws {
        let data = try JSONEncoder().encode(SummarizeReplyDTO(sessionId: "s1", summary: "x"))
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(object["sessionId"] as? String, "s1")
        XCTAssertEqual(object["summary"] as? String, "x")
        XCTAssertNil(object["error"])
        XCTAssertEqual(object.count, 2)
    }

    func testV6_wireCodersRoundTripWithSnakeCaseKey() throws {
        let original = SummarizeReplyDTO(sessionId: "s1", summary: "x", error: "y")
        let data = try StenographerWire.encoder().encode(original)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(object["session_id"] as? String, "s1")
        XCTAssertNil(object["sessionId"])
        let decoded = try StenographerWire.decoder().decode(SummarizeReplyDTO.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func testV7_decodesFailureReply() throws {
        let json = Data(#"{"sessionId":"s1","error":"model too large"}"#.utf8)
        let reply = try JSONDecoder().decode(SummarizeReplyDTO.self, from: json)
        XCTAssertEqual(reply.sessionId, "s1")
        XCTAssertEqual(reply.error, "model too large")
        XCTAssertNil(reply.summary)
    }

    func testV8_decodesWithOptionalsMissingButRequiresSessionId() throws {
        let json = Data(#"{"sessionId":"s1"}"#.utf8)
        let reply = try JSONDecoder().decode(SummarizeReplyDTO.self, from: json)
        XCTAssertNil(reply.summary)
        XCTAssertNil(reply.error)
        XCTAssertThrowsError(try JSONDecoder().decode(SummarizeReplyDTO.self, from: Data("{}".utf8))) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testV9_initializerAcceptsBothSummaryAndError() {
        let reply = SummarizeReplyDTO(sessionId: "s1", summary: "x", error: "y")
        XCTAssertEqual(reply.summary, "x")
        XCTAssertEqual(reply.error, "y")
    }
}
