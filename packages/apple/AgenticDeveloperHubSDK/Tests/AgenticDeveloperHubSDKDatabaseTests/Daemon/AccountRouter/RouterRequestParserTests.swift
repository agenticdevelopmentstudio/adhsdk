import AgenticDeveloperHubSDKCore
import XCTest
@testable import AgenticDeveloperHubSDKDatabase

/// The router's request intake: binary-safe, incremental, strict about the
/// framing inputs a smuggling or confused client would send.
final class RouterRequestParserTests: XCTestCase {

    private func bytes(_ text: String) -> Data { Data(text.utf8) }

    /// Feeds `data` in `piece`-sized slices and returns every event.
    private func parse(_ data: Data, piece: Int = .max,
                       parser: inout RouterRequestParser) throws -> [RequestParseEvent] {
        var events: [RequestParseEvent] = []
        var offset = 0
        while offset < data.count {
            let end = min(data.count, offset + min(piece, data.count - offset))
            events += try parser.feed(data.subdata(in: offset..<end))
            offset = end
        }
        return events
    }

    private func rejection(_ text: String) -> RequestRejection? {
        var parser = RouterRequestParser()
        do {
            _ = try parser.feed(bytes(text))
            return nil
        } catch {
            return error as? RequestRejection
        }
    }

    private func completed(_ events: [RequestParseEvent]) -> (RouterRequestHead, Data)? {
        for event in events {
            if case let .complete(head, body) = event { return (head, body) }
        }
        return nil
    }

    func testPostWithContentLengthYieldsHeadThenBody() throws {
        var parser = RouterRequestParser()
        let events = try parse(bytes(
            "POST /v1/messages?beta=true HTTP/1.1\r\nHost: 127.0.0.1\r\nX-Api-Key: k\r\n"
            + "Content-Length: 5\r\n\r\nhello"), parser: &parser)
        XCTAssertEqual(events.count, 2)
        guard case let .head(head) = events.first else { return XCTFail("no head event first") }
        XCTAssertEqual(head.method, "POST")
        XCTAssertEqual(head.target, "/v1/messages?beta=true")
        XCTAssertEqual(head.path, "/v1/messages")
        XCTAssertEqual(head.fields.map(\.name), ["Host", "X-Api-Key", "Content-Length"])
        XCTAssertEqual(head.value("x-api-key"), "k")
        XCTAssertEqual(completed(events)?.1, bytes("hello"))
        XCTAssertTrue(parser.isComplete)
    }

    func testByteByByteFeedingGivesTheSameRequest() throws {
        var parser = RouterRequestParser()
        let raw = bytes("POST /v1/messages HTTP/1.1\r\nContent-Length: 3\r\n\r\nabc")
        let events = try parse(raw, piece: 1, parser: &parser)
        XCTAssertEqual(completed(events)?.1, bytes("abc"))
    }

    func testRequestWithoutFramingHasAnEmptyBody() throws {
        var parser = RouterRequestParser()
        let events = try parser.feed(bytes("GET /v1/models HTTP/1.1\r\nHost: x\r\n\r\n"))
        XCTAssertEqual(completed(events)?.1, Data())
    }

    func testChunkedBodyWithExtensionsAndTrailers() throws {
        var parser = RouterRequestParser()
        let raw = bytes("POST /v1/messages HTTP/1.1\r\nTransfer-Encoding: chunked\r\n\r\n"
                        + "5;name=x\r\nhello\r\n6\r\n world\r\n0\r\nX-Trailer: t\r\n\r\n")
        let events = try parse(raw, piece: 7, parser: &parser)
        XCTAssertEqual(completed(events)?.1, bytes("hello world"))
    }

    func testBinaryBodyIsKeptByteForByte() throws {
        var parser = RouterRequestParser()
        let payload = Data((0..<1024).map { UInt8($0 % 256) })
        var raw = bytes("POST /v1/messages HTTP/1.1\r\nContent-Length: 1024\r\n\r\n")
        raw.append(payload)
        XCTAssertEqual(completed(try parse(raw, piece: 100, parser: &parser))?.1, payload)
    }

    // Review Focus 3 (parser half).
    func testThirtyMegabyteBodyParsesInPieces() throws {
        let size = 30 * 1024 * 1024
        var payload = Data(count: size)
        payload.withUnsafeMutableBytes { buffer in
            for index in 0..<size { buffer[index] = UInt8(truncatingIfNeeded: index &* 31 &+ 7) }
        }
        var raw = bytes("POST /v1/messages HTTP/1.1\r\nContent-Length: \(size)\r\n\r\n")
        raw.append(payload)
        var parser = RouterRequestParser()
        let body = completed(try parse(raw, piece: 64 * 1024, parser: &parser))?.1
        XCTAssertEqual(body?.count, size)
        XCTAssertTrue(body == payload)

        var chunked = bytes("POST /v1/messages HTTP/1.1\r\nTransfer-Encoding: chunked\r\n\r\n")
        let step = 1024 * 1024
        for start in stride(from: 0, to: size, by: step) {
            chunked.append(bytes(String(step, radix: 16) + "\r\n"))
            chunked.append(payload.subdata(in: start..<(start + step)))
            chunked.append(bytes("\r\n"))
        }
        chunked.append(bytes("0\r\n\r\n"))
        var chunkedParser = RouterRequestParser()
        XCTAssertTrue(completed(try parse(chunked, piece: 50_000, parser: &chunkedParser))?.1 == payload)
    }

    // Review Focus 3 (cap).
    func testOversizedBodyIs413() {
        let declared = RouterRequestParser.maxBodyBytes + 1
        XCTAssertEqual(rejection("POST /v1/messages HTTP/1.1\r\nContent-Length: \(declared)\r\n\r\n"),
                       .payloadTooLarge)

        var parser = RouterRequestParser(maxBodyBytes: 10, maxHeaderBytes: RouterRequestParser.maxHeaderBytes)
        XCTAssertThrowsError(try parser.feed(bytes(
            "POST /v1/messages HTTP/1.1\r\nTransfer-Encoding: chunked\r\n\r\n6\r\nabcdef\r\n6\r\n"))) { error in
            XCTAssertEqual(error as? RequestRejection, .payloadTooLarge)
            XCTAssertEqual((error as? RequestRejection)?.status, 413)
        }
    }

    func testHeaderSectionOver64KiBIs431() {
        let big = String(repeating: "a", count: RouterRequestParser.maxHeaderBytes)
        XCTAssertEqual(rejection("POST /v1/messages HTTP/1.1\r\nX-Big: \(big)\r\n\r\n"), .headersTooLarge)
        XCTAssertEqual(rejection("POST /v1/messages HTTP/1.1\r\nX-Big: \(big)"), .headersTooLarge,
                       "an unterminated head over the cap is refused before it ends")
        XCTAssertEqual(RequestRejection.headersTooLarge.status, 431)
    }

    func testContentLengthWithTransferEncodingIs400() {
        let reply = rejection("POST / HTTP/1.1\r\nContent-Length: 3\r\nTransfer-Encoding: chunked\r\n\r\n")
        XCTAssertEqual(reply?.status, 400)
    }

    func testUnsupportedTransferEncodingIs501() {
        XCTAssertEqual(rejection("POST / HTTP/1.1\r\nTransfer-Encoding: gzip, chunked\r\n\r\n")?.status, 501)
        XCTAssertEqual(rejection("POST / HTTP/1.1\r\nTransfer-Encoding: identity\r\n\r\n")?.status, 501)
    }

    func testMalformedInputIs400() {
        let cases: [(String, String)] = [
            ("POST / HTTP/1.1\r\nX-A: 1\r\n folded\r\n\r\n", "obs-fold"),
            ("POST / HTTP/1.1\r\nX-A: 1\nX-B: 2\r\n\r\n", "bare LF inside the head"),
            ("POST / HTTP/1.1\r\nX-A: a\u{0}b\r\n\r\n", "NUL in a value"),
            ("POST / HTTP/1.1\r\nX-A: a\rb\r\n\r\n", "bare CR in a value"),
            ("POST / HTTP/1.1\r\nX A: 1\r\n\r\n", "space in a name"),
            ("POST / HTTP/1.1\r\n: 1\r\n\r\n", "empty name"),
            ("POST / HTTP/1.1\r\nNoColon\r\n\r\n", "no colon"),
            ("POST http://evil.example/v1/messages HTTP/1.1\r\n\r\n", "absolute-form target"),
            ("OPTIONS * HTTP/1.1\r\n\r\n", "asterisk target"),
            ("POST /v1/messages HTTP/2.0\r\n\r\n", "unsupported version"),
            ("POST  /v1/messages HTTP/1.1\r\n\r\n", "double space in request line"),
            ("P(ST /v1/messages HTTP/1.1\r\n\r\n", "non-token method"),
            ("POST / HTTP/1.1\r\nContent-Length: abc\r\n\r\n", "non-numeric length"),
            ("POST / HTTP/1.1\r\nContent-Length: 5, 6\r\n\r\n", "conflicting lengths"),
            ("POST / HTTP/1.1\r\nContent-Length: 5\r\nContent-Length: 6\r\n\r\n", "conflicting length fields"),
            ("POST / HTTP/1.1\r\nTransfer-Encoding: chunked\r\n\r\nzz\r\n", "bad chunk size"),
            ("POST / HTTP/1.1\r\nTransfer-Encoding: chunked\r\n\r\n3\r\nabcXY", "chunk data without CRLF")
        ]
        for (raw, name) in cases {
            XCTAssertEqual(rejection(raw)?.status, 400, name)
        }
    }

    func testRepeatedIdenticalLengthsAreAccepted() throws {
        var parser = RouterRequestParser()
        let events = try parser.feed(bytes("POST / HTTP/1.1\r\nContent-Length: 2, 2\r\n\r\nok"))
        XCTAssertEqual(completed(events)?.1, bytes("ok"))
    }

    func testExpectContinueIsVisibleOnTheHeadBeforeTheBody() throws {
        var parser = RouterRequestParser()
        let events = try parser.feed(bytes(
            "POST /v1/messages HTTP/1.1\r\nExpect: 100-continue\r\nContent-Length: 4\r\n\r\n"))
        XCTAssertEqual(events.count, 1)
        guard case let .head(head) = events.first else { return XCTFail("no head") }
        XCTAssertTrue(head.expectsContinue)
        XCTAssertFalse(parser.isComplete)
        XCTAssertEqual(completed(try parser.feed(bytes("data")))?.1, bytes("data"))
    }

    func testBytesAfterACompleteRequestAreIgnored() throws {
        var parser = RouterRequestParser()
        _ = try parser.feed(bytes("GET / HTTP/1.1\r\n\r\n"))
        XCTAssertEqual(try parser.feed(bytes("GET /again HTTP/1.1\r\n\r\n")), [])
    }

    func testNineteenDigitAndNegativeContentLengthAre400() {
        XCTAssertEqual(rejection("POST / HTTP/1.1\r\nContent-Length: 1234567890123456789\r\n\r\n")?.status, 400)
        XCTAssertEqual(rejection("POST / HTTP/1.1\r\nContent-Length: -1\r\n\r\n")?.status, 400)
    }

    func testOversizedTrailerIs431EvenWhenUnterminated() {
        let big = String(repeating: "a", count: RouterRequestParser.maxHeaderBytes)
        let head = "POST / HTTP/1.1\r\nTransfer-Encoding: chunked\r\n\r\n0\r\n"
        XCTAssertEqual(rejection(head + "X-T: \(big)\r\n\r\n"), .headersTooLarge)
        XCTAssertEqual(rejection(head + "X-T: \(big)"), .headersTooLarge)
    }

    /// Review fix: a trailer line trickled in one byte at a time is scanned
    /// once, not once per feed, and the cap still applies.
    func testNearCapTrailerFedByteByByteIsFastAndCapped() throws {
        let head = bytes("POST / HTTP/1.1\r\nTransfer-Encoding: chunked\r\n\r\n0\r\n")
        var parser = RouterRequestParser()
        _ = try parser.feed(head)
        let line = bytes("X-T: " + String(repeating: "a", count: RouterRequestParser.maxHeaderBytes - 100))
        let started = Date()
        for byte in line { XCTAssertEqual(try parser.feed(Data([byte])), []) }
        let events = try parser.feed(bytes("\r\n\r\n"))
        XCTAssertNotNil(completed(events))
        XCTAssertLessThan(Date().timeIntervalSince(started), 2)

        var capped = RouterRequestParser()
        _ = try capped.feed(head)
        let over = bytes("X-T: " + String(repeating: "a", count: RouterRequestParser.maxHeaderBytes))
        XCTAssertThrowsError(try { for byte in over { _ = try capped.feed(Data([byte])) } }()) { error in
            XCTAssertEqual(error as? RequestRejection, .headersTooLarge)
        }
    }

    func testUnterminatedHeadOverCapAcrossManyFeedsIs431() {
        var parser = RouterRequestParser()
        let chunk = bytes(String(repeating: "a", count: 1000))
        XCTAssertThrowsError(try {
            _ = try parser.feed(bytes("POST / HTTP/1.1\r\nX: "))
            for _ in 0..<70 { _ = try parser.feed(chunk) }
        }()) { XCTAssertEqual($0 as? RequestRejection, .headersTooLarge) }
    }

    func testOverlongChunkSizeLineAndDuplicateOrUppercaseChunkedCodings() {
        let head = "POST / HTTP/1.1\r\nTransfer-Encoding: chunked\r\n\r\n"
        XCTAssertEqual(rejection(head + String(repeating: "0", count: 2000))?.status, 400)
        let twice = "POST / HTTP/1.1\r\nTransfer-Encoding: chunked\r\nTransfer-Encoding: chunked\r\n\r\n"
        XCTAssertEqual(rejection(twice)?.status, 501)
        var parser = RouterRequestParser()
        XCTAssertNotNil(completed(try parser.feed(bytes(
            "POST / HTTP/1.1\r\nTransfer-Encoding: Chunked\r\n\r\n0\r\n\r\n"))))
    }

    func testANonUTF8FieldValueIsKeptRatherThanEmptied() throws {
        var parser = RouterRequestParser()
        var data = bytes("GET / HTTP/1.1\r\nX-Note: caf")
        data.append(0xE9)
        data.append(bytes("\r\n\r\n"))
        let head = try XCTUnwrap(completed(try parser.feed(data))?.0)
        XCTAssertEqual(head.value("x-note"), "caf\u{E9}")
    }

    /// Final review I2: the body reservation the connection takes before it reads the body.
    func testBodyReservationIsTheDeclaredLengthOrTheCapForChunked() throws {
        var fixed = RouterRequestParser()
        _ = try fixed.feed(bytes("POST / HTTP/1.1\r\nContent-Length: 5\r\n\r\n"))
        XCTAssertEqual(fixed.bodyReservation, 5)
        let events = try fixed.feed(bytes("hello"))
        XCTAssertEqual(completed(events)?.1, bytes("hello"), "the body arrives intact")
        XCTAssertFalse(fixed.growsBody)
        var chunked = RouterRequestParser(maxBodyBytes: 1000)
        _ = try chunked.feed(bytes("POST / HTTP/1.1\r\nTransfer-Encoding: chunked\r\n\r\n"))
        XCTAssertEqual(chunked.bodyReservation, 0, "a chunked body reserves as it grows, not up front")
        XCTAssertTrue(chunked.growsBody)
        XCTAssertEqual(chunked.maxBody, 1000)
        XCTAssertEqual(chunked.bytesHeld, 0)
        _ = try chunked.feed(bytes("5\r\nhello\r\n3\r\nab"))
        XCTAssertEqual(chunked.bytesHeld, 7, "de-chunked bytes plus the partial chunk")
        let done = try chunked.feed(bytes("c\r\n0\r\n\r\n"))
        XCTAssertEqual(completed(done)?.1, bytes("helloabc"))
        XCTAssertFalse(chunked.growsBody)
        var none = RouterRequestParser()
        _ = try none.feed(bytes("GET / HTTP/1.1\r\n\r\n"))
        XCTAssertEqual(none.bodyReservation, 0)
    }
}
