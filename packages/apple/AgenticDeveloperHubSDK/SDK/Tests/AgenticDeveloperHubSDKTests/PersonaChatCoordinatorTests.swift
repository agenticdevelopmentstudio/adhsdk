import XCTest
@testable import AgenticDeveloperHubSDK

/// Conformance vectors for the `persona-chat-coordinator` ingredient.
/// docs/specs/ingredients/persona-chat-coordinator.md — one test per `pcc-*`
/// vector, named for the requirement it holds the coordinator to.
///
/// The same vectors run against the TypeScript coordinator in
/// `packages/web/packages/chat/src/backends/__tests__/personaChatConformance.test.ts`.
/// Two implementations of one spec are only worth having if the same
/// scenarios prove both.
@MainActor
final class PersonaChatCoordinatorTests: XCTestCase {
    nonisolated private static let hello = [("token", #"{"text":"Hel"}"#), ("token", #"{"text":"lo"}"#), ("done", "{}")]

    // MARK: Conversation lifecycle

    func test_pcc001_lazyConversation_constructedCoordinatorMakesNoRequests() async {
        let f = makeFixture { sse(Self.hello) }
        defer { f.tearDown() }

        await f.collector.quiesce()

        XCTAssertTrue(f.requests.all.isEmpty)
    }

    func test_pcc002_conversationReuse_twoSendsShareOneConversation() async throws {
        let f = makeFixture { sse(Self.hello) }
        defer { f.tearDown() }

        _ = try await f.coordinator.send(text: "one", attachments: [])
        await f.collector.wait(for: 4)
        _ = try await f.coordinator.send(text: "two", attachments: [])
        await f.collector.wait(for: 8)

        XCTAssertEqual(f.requests.requests(matching: "/v1/chats").count, 1)
        XCTAssertEqual(f.requests.requests(matching: "/messages").count, 2)
    }

    func test_pcc003_noHistory_requestCarriesOnlyTheNewMessage() async throws {
        let f = makeFixture { sse(Self.hello) }
        defer { f.tearDown() }

        _ = try await f.coordinator.send(text: "hello", attachments: [])
        await f.collector.waitForTurnEnd()

        let post = try XCTUnwrap(f.requests.requests(matching: "/messages").first)
        let body = try XCTUnwrap(post.httpBody)
        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: body) as? [String: Any]
        )
        XCTAssertEqual(Array(json.keys), ["message"])
        XCTAssertEqual(json["message"] as? String, "hello")
    }

    // MARK: Streaming

    func test_pcc004_accumulate_draftsCarryTheWholeTextSoFar() async throws {
        let f = makeFixture { sse(Self.hello) }
        defer { f.tearDown() }

        _ = try await f.coordinator.send(text: "hey", attachments: [])
        let events = await f.collector.waitForTurnEnd()

        XCTAssertEqual(events.compactMap(\.draftText), ["Hel", "Hello"])
    }

    func test_pcc005_commitOnce_oneMessageThenTheDraftClears() async throws {
        let f = makeFixture { sse(Self.hello) }
        defer { f.tearDown() }

        _ = try await f.coordinator.send(text: "hey", attachments: [])
        let events = await f.collector.waitForTurnEnd()

        let messages = events.compactMap(\.receivedMessage)
        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(messages.first?.text, "Hello")
        let commitIndex = try XCTUnwrap(events.firstIndex { $0.receivedMessage != nil })
        let clearIndex = try XCTUnwrap(events.firstIndex(where: \.isDraftCleared))
        XCTAssertLessThan(commitIndex, clearIndex)
    }

    func test_pcc006_noCommitOnAbort_truncatedReplyDoesNotCommit() async throws {
        let f = makeFixture { truncatedSse([("token", #"{"text":"par"}"#)]) }
        defer { f.tearDown() }

        _ = try await f.coordinator.send(text: "hey", attachments: [])
        let events = await f.collector.waitForTurnEnd()

        XCTAssertTrue(events.compactMap(\.receivedMessage).isEmpty)
        XCTAssertTrue(events.contains(where: \.isDraftCleared))
        XCTAssertNotNil(events.compactMap(\.transportErrorMessage).first)
    }

    func test_pcc007_dropOpen_theHeartbeatIsNotATranscriptEvent() async throws {
        let f = makeFixture {
            sse([("open", "{}"), ("token", #"{"text":"hi"}"#), ("done", "{}")])
        }
        defer { f.tearDown() }

        _ = try await f.coordinator.send(text: "hey", attachments: [])
        let events = await f.collector.waitForTurnEnd()

        XCTAssertEqual(events.compactMap(\.draftText), ["hi"])
        // draftUpdated, messageReceived, draftCleared. statusChanged events also
        // arrive on this stream (ci-status-out-of-band lives in the payload,
        // not in keeping status off the stream) so they're excluded here rather
        // than counted as transcript events.
        XCTAssertEqual(events.filter { !$0.isStatusChanged }.count, 3)
    }

    func test_pcc008_unknownEvents_areIgnoredAndTheStreamContinues() async throws {
        let f = makeFixture {
            sse([
                ("quux", #"{"whatever":true}"#),
                ("token", #"{"text":"hi"}"#),
                ("done", "{}"),
            ])
        }
        defer { f.tearDown() }

        _ = try await f.coordinator.send(text: "hey", attachments: [])
        let events = await f.collector.waitForTurnEnd()

        XCTAssertEqual(events.compactMap(\.receivedMessage).first?.text, "hi")
    }

    // MARK: Tool calls

    func test_pcc009_toolCalls_completionCorrelatesToItsInvocation() async throws {
        let f = makeFixture {
            sse([
                ("tool_call_started", #"{"name":"search","arguments":"{\"q\":\"x\"}"}"#),
                ("tool_call_completed", #"{"name":"search","ok":true,"result":"{\"hits\":2}"}"#),
                ("done", "{}"),
            ])
        }
        defer { f.tearDown() }

        _ = try await f.coordinator.send(text: "find x", attachments: [])
        let events = await f.collector.waitForTurnEnd()

        let invocation = try XCTUnwrap(events.compactMap(\.invocation).first)
        let result = try XCTUnwrap(events.compactMap(\.commandResult).first)
        XCTAssertEqual(invocation.commandName, "search")
        XCTAssertEqual(invocation.argumentsJSON, #"{"q":"x"}"#)
        XCTAssertEqual(result.invocationID, invocation.id)
        XCTAssertTrue(result.ok)
        XCTAssertEqual(result.resultJSON, #"{"hits":2}"#)
    }

    func test_pcc010_invocationIDs_twoCallsOfOneCommandGetDistinctIDs() async throws {
        let f = makeFixture {
            sse([
                ("tool_call_started", #"{"name":"search","arguments":"{}"}"#),
                ("tool_call_started", #"{"name":"search","arguments":"{}"}"#),
                ("done", "{}"),
            ])
        }
        defer { f.tearDown() }

        _ = try await f.coordinator.send(text: "find x", attachments: [])
        let events = await f.collector.waitForTurnEnd()

        let ids = events.compactMap(\.invocation).map(\.id)
        XCTAssertEqual(ids.count, 2)
        XCTAssertNotEqual(ids[0], ids[1])
    }

    func test_pcc011_toolTextSeparation_theDraftCarriesNoToolPayloads() async throws {
        let f = makeFixture {
            sse([
                ("token", #"{"text":"Looking"}"#),
                ("tool_call_started", #"{"name":"search","arguments":"{\"q\":\"secret\"}"}"#),
                ("tool_call_completed", #"{"name":"search","ok":true,"result":"classified"}"#),
                ("token", #"{"text":" — found it."}"#),
                ("done", "{}"),
            ])
        }
        defer { f.tearDown() }

        _ = try await f.coordinator.send(text: "find x", attachments: [])
        let events = await f.collector.waitForTurnEnd()

        let drafts = events.compactMap(\.draftText)
        XCTAssertEqual(drafts, ["Looking", "Looking — found it."])
        for draft in drafts {
            XCTAssertFalse(draft.contains("secret"))
            XCTAssertFalse(draft.contains("classified"))
        }
        XCTAssertEqual(events.compactMap(\.receivedMessage).first?.text, "Looking — found it.")
    }

    // MARK: Failure

    func test_pcc012_errorTerminal_theTurnFailsInsteadOfCommitting() async throws {
        let f = makeFixture {
            sse([("token", #"{"text":"par"}"#), ("error", #"{"message":"upstream exploded"}"#)])
        }
        defer { f.tearDown() }

        let localID = try await f.coordinator.send(text: "hey", attachments: [])
        let events = await f.collector.waitForTurnEnd()

        XCTAssertTrue(events.compactMap(\.receivedMessage).isEmpty)
        XCTAssertEqual(events.compactMap(\.failureReason).first, "upstream exploded")
        guard case let .messageFailed(failedID, _)? = events.first(where: { $0.failureReason != nil })
        else { return XCTFail("expected a messageFailed event") }
        XCTAssertEqual(failedID, localID)
    }

    func test_pcc013_inBandErrors_http200IsNotSuccess() async throws {
        let f = makeFixture {
            sse([("error", #"{"message":"model refused"}"#)])
        }
        defer { f.tearDown() }

        _ = try await f.coordinator.send(text: "hey", attachments: [])
        let events = await f.collector.waitForTurnEnd()

        XCTAssertEqual(events.compactMap(\.failureReason).first, "model refused")
        XCTAssertTrue(events.compactMap(\.receivedMessage).isEmpty)
    }

    func test_conversationCreationFailure_isReportedAgainstTheMessage() async throws {
        let f = makeFixture(conversationStatus: 500) { sse(Self.hello) }
        defer { f.tearDown() }

        _ = try await f.coordinator.send(text: "hey", attachments: [])
        let events = await f.collector.waitForTurnEnd()

        XCTAssertEqual(
            events.compactMap(\.failureReason).first,
            "Couldn't start the conversation (500)."
        )
        XCTAssertTrue(f.requests.requests(matching: "/messages").isEmpty)
    }

    // MARK: Cancellation

    func test_pcc014_destroyAuthoritative_cancelsTheInFlightTurn() async throws {
        let cancelled = CancellationFlag()
        let f = makeFixture { hangingSse([("token", #"{"text":"half"}"#)], cancelled: cancelled) }

        _ = try await f.coordinator.send(text: "hey", attachments: [])
        await f.collector.wait(for: 1)
        XCTAssertFalse(cancelled.wasCancelled)

        f.coordinator.destroy()
        let events = await f.collector.quiesce(0.2)
        f.pump.cancel()

        XCTAssertTrue(cancelled.wasCancelled)
        XCTAssertTrue(events.contains(where: \.isDraftCleared))
        XCTAssertTrue(events.compactMap(\.receivedMessage).isEmpty)
    }

    func test_pcc015_noReuseAfterDestroy_sendFailsFast() async {
        let f = makeFixture { sse(Self.hello) }
        defer { f.tearDown() }

        f.coordinator.destroy()

        do {
            _ = try await f.coordinator.send(text: "hey", attachments: [])
            XCTFail("expected send to throw")
        } catch {
            XCTAssertTrue(error is PersonaChatError)
        }
        XCTAssertTrue(f.requests.all.isEmpty)
    }

    // MARK: Status

    func test_pcc016_statusOutOfBand_retryDrivesStatusNotTheTranscript() async throws {
        let f = makeFixture {
            sse([
                ("status", #"{"phase":"retrying","attempt":2}"#),
                ("token", #"{"text":"hi"}"#),
                ("done", "{}"),
            ])
        }
        defer { f.tearDown() }

        _ = try await f.coordinator.send(text: "hey", attachments: [])
        let events = await f.collector.waitForTurnEnd()

        XCTAssertEqual(f.statuses.all, [.thinking, .retrying, .responding, nil])
        // Three transcript events: the draft, the commit, the clear. The retry
        // is not one of them — it only ever reaches the transcript-shaped
        // events by way of statusChanged, which is excluded here, and never as
        // a Message (ci-status-out-of-band).
        XCTAssertEqual(events.filter { !$0.isStatusChanged }.count, 3)
        // Every callback-reported status also reached the stream as an event.
        XCTAssertEqual(events.filter(\.isStatusChanged).count, f.statuses.all.count)
    }

    func test_statusClearsOnEveryExitPath() async throws {
        let f = makeFixture { truncatedSse([("token", #"{"text":"par"}"#)]) }
        defer { f.tearDown() }

        _ = try await f.coordinator.send(text: "hey", attachments: [])
        await f.collector.waitForTurnEnd()

        XCTAssertEqual(f.statuses.all.last, TurnStatus?.none)
    }

    // MARK: Contract edges

    func test_attachmentsAreRefusedRatherThanDroppedSilently() async {
        let f = makeFixture { sse(Self.hello) }
        defer { f.tearDown() }

        do {
            _ = try await f.coordinator.send(text: "hey", attachments: [StubAttachment()])
            XCTFail("expected send to throw")
        } catch {
            XCTAssertTrue(error is PersonaChatError)
        }
        XCTAssertTrue(f.requests.all.isEmpty)
    }

    func test_emptyReplyStillCommits() async throws {
        let f = makeFixture { sse([("done", "{}")]) }
        defer { f.tearDown() }

        _ = try await f.coordinator.send(text: "hey", attachments: [])
        let events = await f.collector.waitForTurnEnd()

        XCTAssertEqual(events.compactMap(\.receivedMessage).count, 1)
        XCTAssertEqual(events.compactMap(\.receivedMessage).first?.text, "")
    }
}

private struct StubAttachment: Attachment {
    let id = "att-1"
    let mediaType: any MediaType = StubMediaType()
    let source: AttachmentSource = .remote(URL(string: "https://example.test/x.png")!)
    let presentation: AttachmentPresentation = .inline
    let displayName: String? = nil
    let byteSize: Int? = nil
}

private struct StubMediaType: MediaType {
    let identifier = "image/png"
}
