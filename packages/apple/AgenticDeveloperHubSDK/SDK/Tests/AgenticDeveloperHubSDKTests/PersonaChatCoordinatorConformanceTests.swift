import XCTest
@testable import AgenticDeveloperHubSDK

/// Conformance vectors pcc-021 to pcc-033 for the `persona-chat-coordinator` recipe.
/// pcc-001 to pcc-020 live in `PersonaChatCoordinatorTests`.
@MainActor
final class PersonaChatCoordinatorConformanceTests: XCTestCase {
    // MARK: SSEParser

    func test_pcc021_sseBlockBoundary_splitMidWordYieldsOneBlockOnceSeparatorArrives() {
        var parser = SSEParser()
        let first = parser.consume(Data("event:token\ndata:{\"te".utf8))
        XCTAssertTrue(first.isEmpty)
        let second = parser.consume(Data("xt\":\"hi\"}\n".utf8))
        XCTAssertTrue(second.isEmpty, "a lone newline is not yet a block separator")
        let third = parser.consume(Data("\n".utf8))
        XCTAssertEqual(third, [SSEBlock(event: "token", data: #"{"text":"hi"}"#)])
        XCTAssertTrue(parser.consume(Data()).isEmpty, "the block is not yielded twice")
    }

    func test_pcc022_sseDefaultEventNameAndComments_commentLineContributesNothing() {
        var parser = SSEParser()
        let blocks = parser.consume(Data(": a comment\ndata: hello\n\n".utf8))
        XCTAssertEqual(blocks, [SSEBlock(event: "message", data: "hello")])
    }

    func test_pcc023_sseSingleLeadingSpaceStripped_onlyTheFirstSpaceGoes() {
        var parser = SSEParser()
        let blocks = parser.consume(Data("event: token\ndata:  two spaces\n\n".utf8))
        XCTAssertEqual(blocks.first?.data, " two spaces")
        XCTAssertEqual(blocks.first?.event, "token")
    }

    func test_pcc024_sseInvalidUTF8Dropped_parsingContinuesWithTheNextSegment() {
        var parser = SSEParser()
        var chunk = Data("event: a\ndata: one\n\n".utf8)
        chunk.append(contentsOf: [0xFF, 0xFE, 0xFD])
        chunk.append(contentsOf: Array("\n\n".utf8))
        chunk.append(contentsOf: Array("event: b\ndata: two\n\n".utf8))
        let blocks = parser.consume(chunk)
        XCTAssertEqual(blocks, [
            SSEBlock(event: "a", data: "one"),
            SSEBlock(event: "b", data: "two")
        ])
    }

    // MARK: Options and send

    func test_pcc025_modelOverride_bodyCarriesTheModelOnlyWhenSet() async throws {
        let withModel = try await conversationBody(model: "model-x")
        XCTAssertEqual(withModel["model"] as? String, "model-x")
        let without = try await conversationBody(model: nil)
        XCTAssertFalse(without.keys.contains("model"))
        XCTAssertEqual(without["persona_slug"] as? String, "aria")
    }

    func test_pcc026_sendReturnsLocalIDImmediately_beforeAnyBlockIsRead() async throws {
        let f = makeFixture { AsyncThrowingStream { _ in } }
        defer { f.tearDown() }

        let localID = try await f.coordinator.send(text: "hey", attachments: [])

        XCTAssertNotNil(UUID(uuidString: localID))
        let events = await f.collector.quiesce(0.1)
        XCTAssertTrue(events.compactMap(\.draftText).isEmpty)
        XCTAssertTrue(events.compactMap(\.receivedMessage).isEmpty)
    }

    func test_pcc027_localTypingNoop_returnsAndEmitsNothing() async throws {
        let f = makeFixture { sse([("done", "{}")]) }
        defer { f.tearDown() }

        try await f.coordinator.setLocalTyping(true)

        let events = await f.collector.quiesce(0.1)
        XCTAssertTrue(events.isEmpty)
        XCTAssertTrue(f.requests.all.isEmpty)
    }

    func test_pcc028_widgetResponseUnsupported_alwaysThrowsWidgetsUnsupported() async {
        let f = makeFixture { sse([("done", "{}")]) }
        defer { f.tearDown() }

        do {
            try await f.coordinator.submitWidgetResponse(StubWidgetResponse())
            XCTFail("expected submitWidgetResponse to throw")
        } catch let error as PersonaChatError {
            guard case .widgetsUnsupported = error else { return XCTFail("wrong error \(error)") }
        } catch {
            XCTFail("unexpected error \(error)")
        }
    }

    func test_pcc029_destroyIdempotent_secondDestroyKeepsSendRejected() async {
        let f = makeFixture { sse([("done", "{}")]) }
        defer { f.tearDown() }

        f.coordinator.destroy()
        await assertSendThrowsDestroyed(f.coordinator)
        f.coordinator.destroy()
        await assertSendThrowsDestroyed(f.coordinator)
        XCTAssertTrue(f.requests.all.isEmpty)
    }

    func test_pcc030_openInvocationsClearedPerTurn_laterCompletionFindsNothingOpen() async throws {
        let turns = TurnCounter()
        let f = makeFixture {
            if turns.next() == 1 {
                return truncatedSse([("tool_call_started", #"{"name":"x","arguments":"{}"}"#)])
            }
            let completed = #"{"name":"x","ok":true,"result":"r"}"#
            return sse([("tool_call_completed", completed), ("done", "{}")])
        }
        defer { f.tearDown() }

        _ = try await f.coordinator.send(text: "turn A", attachments: [])
        await waitForDraftClears(1, in: f.collector)
        _ = try await f.coordinator.send(text: "turn B", attachments: [])
        await waitForDraftClears(2, in: f.collector)

        let events = await f.collector.all
        XCTAssertEqual(events.compactMap(\.invocation).count, 1)
        XCTAssertTrue(events.compactMap(\.commandResult).isEmpty)
        XCTAssertEqual(events.compactMap(\.receivedMessage).count, 1)
    }

    func test_pcc031_errorDescriptionPrefersPersonaChatError_conversationFailureText() async throws {
        let f = makeFixture(conversationStatus: 503) { sse([("done", "{}")]) }
        defer { f.tearDown() }

        _ = try await f.coordinator.send(text: "hey", attachments: [])
        let events = await f.collector.waitForTurnEnd()

        let expected = "Couldn't start the conversation (503)."
        XCTAssertEqual(events.compactMap(\.failureReason).first, expected)
        XCTAssertEqual(PersonaChatError.conversationFailed(status: 503).description, expected)
    }

    func test_pcc032_isolationAndSendable_destroyIsCallableSynchronouslyFromAnyContext() async {
        let f = makeFixture { AsyncThrowingStream { _ in } }
        // Compile-time: `Authorize` is `@Sendable`, so this assignment is checked by the compiler.
        let authorize: Authorize = { _ in
            AuthorizedResponse(statusCode: 200, body: AsyncThrowingStream { $0.finish() })
        }
        let sendable: @Sendable (URLRequest) async throws -> AuthorizedResponse = authorize
        XCTAssertNotNil(sendable)

        let coordinator = f.coordinator
        await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                Self.destroyFromNonisolatedContext(coordinator)
                continuation.resume()
            }
        }
        // destroy() finished the stream synchronously, so the collector's pump ends.
        await f.pump.value
        await assertSendThrowsDestroyed(coordinator)
    }

    func test_pcc033_defaultAuthorizeFactory_chunksEndWithNewlineAndStatusIsReported() async throws {
        let session = StubURLProtocol.makeSession()
        let httpURL = try XCTUnwrap(URL(string: "https://stub.test/\(UUID().uuidString)"))
        let http = try XCTUnwrap(
            HTTPURLResponse(url: httpURL, statusCode: 207, httpVersion: nil, headerFields: nil)
        )
        let wire = [Data("event: token\ndata: {}\n".utf8), Data("\npartial".utf8)]
        StubURLProtocol.registry.set(response: http, chunks: wire, for: httpURL)

        let authorize = PersonaChatCoordinator.urlSessionAuthorize(session: session)
        let response = try await authorize(URLRequest(url: httpURL))

        XCTAssertEqual(response.statusCode, 207)
        var chunks: [String] = []
        for try await chunk in response.body { chunks.append(String(decoding: chunk, as: UTF8.self)) }
        XCTAssertEqual(chunks, ["event: token\n", "data: {}\n", "\n", "partial"])

        let plainURL = try XCTUnwrap(URL(string: "stubscheme://host/\(UUID().uuidString)"))
        let plain = URLResponse(
            url: plainURL, mimeType: nil, expectedContentLength: 0, textEncodingName: nil
        )
        StubURLProtocol.registry.set(response: plain, chunks: [Data("x\n".utf8)], for: plainURL)
        let plainResponse = try await authorize(URLRequest(url: plainURL))
        XCTAssertEqual(plainResponse.statusCode, 0)
    }

    // MARK: Helpers

    nonisolated private static func destroyFromNonisolatedContext(_ coordinator: PersonaChatCoordinator) {
        coordinator.destroy()
    }

    private func assertSendThrowsDestroyed(_ coordinator: PersonaChatCoordinator) async {
        do {
            _ = try await coordinator.send(text: "hey", attachments: [])
            XCTFail("expected send to throw")
        } catch let error as PersonaChatError {
            guard case .destroyed = error else { return XCTFail("wrong error \(error)") }
        } catch {
            XCTFail("unexpected error \(error)")
        }
    }

    private func waitForDraftClears(_ count: Int, in collector: EventCollector) async {
        let deadline = Date().addingTimeInterval(2)
        while Date() < deadline {
            let cleared = await collector.all.filter(\.isDraftCleared).count
            if cleared >= count { break }
            try? await Task.sleep(nanoseconds: 1_000_000)
        }
        try? await Task.sleep(nanoseconds: 20_000_000)
    }

    /// Sends once against a conversation endpoint that refuses, so the only thing recorded
    /// that matters is the `/v1/chats` creation body.
    private func conversationBody(model: String?) async throws -> [String: Any] {
        let requests = RequestLog()
        let coordinator = PersonaChatCoordinator(options: PersonaChatCoordinatorOptions(
            personaSlug: "aria",
            baseURL: try XCTUnwrap(URL(string: "https://adh.test/api")),
            authorize: { request in
                requests.record(request)
                return AuthorizedResponse(statusCode: 500, body: AsyncThrowingStream { $0.finish() })
            },
            model: model
        ))
        let collector = EventCollector()
        let pump = Task { await collector.consume(coordinator.inboundEvents) }
        defer {
            coordinator.destroy()
            pump.cancel()
        }
        _ = try await coordinator.send(text: "hey", attachments: [])
        await collector.waitForTurnEnd()
        let post = try XCTUnwrap(requests.requests(matching: "/v1/chats").first)
        let body = try XCTUnwrap(post.httpBody)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
    }
}

private struct StubWidgetResponse: WidgetResponse {
    let widgetID = "widget-1"
    let respondingParticipantID = "user-1"
    let payloadJSON = "{}"
}

private final class TurnCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    func next() -> Int {
        lock.lock()
        defer { lock.unlock() }
        count += 1
        return count
    }
}

private final class StubRegistry: @unchecked Sendable {
    private let lock = NSLock()
    private var entries: [String: (URLResponse, [Data])] = [:]

    func set(response: URLResponse, chunks: [Data], for url: URL) {
        lock.lock()
        defer { lock.unlock() }
        entries[url.absoluteString] = (response, chunks)
    }

    func entry(for url: URL) -> (URLResponse, [Data])? {
        lock.lock()
        defer { lock.unlock() }
        return entries[url.absoluteString]
    }
}

private final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    static let registry = StubRegistry()

    static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: config)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url, let (response, chunks) = Self.registry.entry(for: url) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        for chunk in chunks { client?.urlProtocol(self, didLoad: chunk) }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
