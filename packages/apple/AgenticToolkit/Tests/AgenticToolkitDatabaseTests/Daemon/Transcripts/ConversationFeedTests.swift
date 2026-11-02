import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitDatabase

/// Covers the read that backs the Conversations window: the global newest-first
/// feed over the event store's messages, its attribution join, and the
/// work-output filter.
///
/// The classification rules themselves live in `ConversationExtractorTests`;
/// what is pinned here is everything the database adds on top — ordering,
/// paging, which session a line is labelled with, and the work-output filter
/// that leaves the feed holding the conversation and nothing else. Every line
/// goes in the way the daemon takes it: appended to a transcript file, read by
/// the Claude pipeline's tailer, drained into `events.db`.
final class ConversationFeedTests: XCTestCase {

    private var root: URL!
    private var harness: ClaudePipelineTestHarness!
    private var store: ConversationStore!
    private var database: DaemonDatabase { harness.database }

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("conversation-feed-\(UUID().uuidString)", isDirectory: true)
        harness = try ClaudePipelineTestHarness(directory: root)
        store = ConversationStore(database: harness.database)
    }

    override func tearDownWithError() throws {
        store = nil
        harness = nil
        try? FileManager.default.removeItem(at: root)
    }

    // MARK: - Helpers

    /// One transcript line: `json` (an object starting `{"type":…`) with the
    /// session, a fresh uuid and — unless `timestamp` is nil — its time put in
    /// front, as Claude Code writes them.
    private func line(session: String, at timestamp: String?, json: String) -> String {
        var envelope = #"{"sessionId":"\#(session)","uuid":"\#(UUID().uuidString)""#
        if let timestamp { envelope += #","timestamp":"\#(timestamp)""# }
        return envelope + "," + json.dropFirst()
    }

    private func prompt(session: String, at timestamp: String?, _ text: String) -> String {
        line(session: session, at: timestamp,
             json: #"{"type":"user","message":{"role":"user","content":"\#(text)"}}"#)
    }

    private func reply(session: String, at timestamp: String, _ text: String) -> String {
        line(session: session, at: timestamp,
             json: #"{"type":"assistant","message":{"role":"assistant","stop_reason":"end_turn","#
                 + #""content":[{"type":"text","text":"\#(text)"}]}}"#)
    }

    private func progress(session: String, at timestamp: String, _ text: String) -> String {
        line(session: session, at: timestamp,
             json: #"{"type":"assistant","message":{"role":"assistant","stop_reason":"tool_use","#
                 + #""content":[{"type":"text","text":"\#(text)"}]}}"#)
    }

    private func thinkingThenText(session: String, at timestamp: String) -> String {
        line(session: session, at: timestamp,
             json: #"{"type":"assistant","message":{"role":"assistant","stop_reason":"end_turn","#
                 + #""content":[{"type":"thinking","thinking":"weighing it"},"#
                 + #"{"type":"text","text":"go with B"}]}}"#)
    }

    private func ingest(_ lines: [String], session: String) throws {
        try harness.ingestTranscript(lines: lines, file: harness.transcriptFile(sessionId: session))
    }

    private func makeSession(cwd: String, branch: String) throws -> String {
        let session = UUID().uuidString
        try database.createSessionStubIfMissing(
            sessionId: session,
            cwd: cwd,
            model: "claude-opus-5",
            startedAt: "2026-09-01T00:00:00Z",
            lastActivityAt: "2026-09-01T00:00:00Z",
            gitBranch: branch,
            accountEmail: ""
        )
        return session
    }

    private func feed(
        limit: Int = 50, work: Bool = false, before: String? = nil, session: String? = nil
    ) throws -> [ConversationEntryDTO] {
        try store.conversationEntries(
            limit: limit, includeWorkOutput: work, before: before, sessionId: session)
    }

    // MARK: - The feed itself

    func testTheFeedInterleavesEverySessionNewestFirst() throws {
        // The window is a group chat, not a per-session log: two sessions talking
        // at once have to come back on one timeline, ordered by when things were
        // said and not by which session said them.
        let first = try makeSession(cwd: "/src/alpha", branch: "main")
        let second = try makeSession(cwd: "/src/beta", branch: "main")
        try ingest([
            prompt(session: first, at: "2026-09-01T10:00:00Z", "alpha asks"),
            reply(session: first, at: "2026-09-01T10:00:02Z", "alpha answers")
        ], session: first)
        try ingest([
            prompt(session: second, at: "2026-09-01T10:00:01Z", "beta asks")
        ], session: second)

        XCTAssertEqual(try feed().map(\.text), ["alpha answers", "beta asks", "alpha asks"])
    }

    func testEachLineIsLabelledWithTheSessionItCameFrom() throws {
        // Attribution travels with the entry because the feed spans sessions —
        // a row the window can't label is a row it can't render.
        let session = try makeSession(cwd: "/Users/me/Development/stenographer", branch: "conversations")
        try database.updateSessionTranscriptTitle(
            sessionId: session, title: "conversations window", source: "custom")
        try ingest([
            prompt(session: session, at: "2026-09-01T10:00:00Z", "hi")
        ], session: session)

        let entry = try XCTUnwrap(try feed().first)
        XCTAssertEqual(entry.sessionId, session)
        XCTAssertEqual(entry.projectName, "stenographer")
        XCTAssertEqual(entry.gitBranch, "conversations")
        XCTAssertEqual(entry.sessionName, "conversations window")
    }

    func testAnUntitledSessionIsLabelledWithWhateverItHas() throws {
        // Titles arrive late — the enricher writes one when the session ends. A
        // live session is exactly the one a human most wants to see, so it has to
        // render with an empty name rather than be held back.
        let session = try makeSession(cwd: "/src/gamma", branch: "")
        try ingest([
            prompt(session: session, at: "2026-09-01T10:00:00Z", "hi")
        ], session: session)

        let entry = try XCTUnwrap(try feed().first)
        XCTAssertEqual(entry.projectName, "gamma")
        XCTAssertEqual(entry.sessionName, "")
        XCTAssertEqual(entry.gitBranch, "")
    }

    func testASummaryIsNotAName() throws {
        // The summarizer's line says what a session is doing. Headed as its
        // name, an unnamed session read as one called "writing a file".
        let session = try makeSession(cwd: "/src/adh-tools", branch: "main")
        database.updateSessionSummary("writing test_status_cmd.py", sessionId: session)
        try ingest([
            prompt(session: session, at: "2026-09-01T10:00:00Z", "hi")
        ], session: session)

        XCTAssertEqual(try XCTUnwrap(try feed().first).sessionName, "")
    }

    func testASidechainIsNotPartOfTheConversation() throws {
        // A subagent's exchange with its parent is machinery; the conversation
        // is the human's with the main agent.
        let session = try makeSession(cwd: "/src/beta2", branch: "main")
        try ingest([
            prompt(session: session, at: "2026-09-01T10:00:00Z", "main thread"),
            line(session: session, at: "2026-09-01T10:00:01Z",
                 json: #"{"type":"user","isSidechain":true,"message":{"role":"user","content":"to the subagent"}}"#)
        ], session: session)

        XCTAssertEqual(try feed(work: true).map(\.text), ["main thread"])
    }

    // MARK: - What there is to read

    func testWithoutAnEventStoreTheFeedIsEmpty() throws {
        // A session database with no event store attached: the legacy table
        // holds a line, and the feed does not read it — it is empty, not an error.
        let made = try TestDaemonDatabase.makeSessionDatabase()
        defer { TestDaemonDatabase.remove(path: made.path) }
        try made.db.insertTranscriptLines([
            JSONLScanner.RawTranscriptLine(
                lineNo: 1, sessionId: "s1", entryUuid: "u1", parentUuid: "",
                entryType: "user", role: "user", timestamp: "2026-09-01T10:00:00Z", isSidechain: false,
                rawJSON: #"{"type":"user","message":{"role":"user","content":"legacy"}}"#,
                isQueuedPrompt: false)
        ], filePath: "/tmp/s1.jsonl")

        XCTAssertEqual(try ConversationStore(database: made.db).conversationEntries(
            limit: 50, includeWorkOutput: true, before: nil, sessionId: nil), [])
        XCTAssertEqual(try ConversationStore(database: made.db).conversationEntries(
            limit: 50, includeWorkOutput: true, before: nil, sessionId: "s1"), [])
    }

    func testAnEmptyEventStoreIsAnEmptyFeed() throws {
        XCTAssertEqual(try feed(work: true), [])
        XCTAssertEqual(try feed(work: true, session: "nobody"), [])
        XCTAssertEqual(try feed(before: "2026-09-01T10:00:00Z"), [])
    }

    // MARK: - Timestamps

    func testTimestampsCarryMillisecondsAndPageWithinOneSecond() throws {
        // Two prompts in the same second must page apart: the cursor is the
        // rendered timestamp, so it has to keep the milliseconds.
        let session = try makeSession(cwd: "/src/ms", branch: "main")
        try ingest([
            prompt(session: session, at: "2026-09-01T10:00:00.123Z", "earlier"),
            prompt(session: session, at: "2026-09-01T10:00:00.500Z", "later")
        ], session: session)

        let page = try feed(limit: 1)
        XCTAssertEqual(page.map(\.text), ["later"])
        XCTAssertEqual(page.first?.timestamp, "2026-09-01T10:00:00.500Z")
        let older = try feed(limit: 1, before: page.first?.timestamp)
        XCTAssertEqual(older.map(\.text), ["earlier"])
        XCTAssertEqual(older.first?.timestamp, "2026-09-01T10:00:00.123Z")
        XCTAssertEqual(try feed(limit: 1, before: older.first?.timestamp), [])
    }

    func testASecondsOnlyTimestampRendersWithZeroMilliseconds() throws {
        let session = try makeSession(cwd: "/src/sec", branch: "main")
        try ingest([prompt(session: session, at: "2026-09-01T10:00:00Z", "hi")], session: session)

        XCTAssertEqual(try feed().first?.timestamp, "2026-09-01T10:00:00.000Z")
    }

    func testAnUntimedMessageIsShownAtTheOldestEnd() throws {
        // A line with no timestamp is stored at the epoch. It is a real message,
        // so it is shown — after everything that has a time, stamped 1970 — and
        // a cursor taken from it has nothing older to return.
        let session = try makeSession(cwd: "/src/untimed", branch: "main")
        try ingest([
            prompt(session: session, at: nil, "no time on this one"),
            prompt(session: session, at: "2026-09-01T10:00:00Z", "timed")
        ], session: session)

        let page = try feed()
        XCTAssertEqual(page.map(\.text), ["timed", "no time on this one"])
        XCTAssertEqual(page.last?.timestamp, "1970-01-01T00:00:00.000Z")
        XCTAssertEqual(try feed(limit: 1, before: "2026-09-01T10:00:00.000Z").map(\.text),
                       ["no time on this one"])
        XCTAssertEqual(try feed(before: page.last?.timestamp), [])
    }

    func testAnUnreadableCursorReturnsNothing() throws {
        let session = try makeSession(cwd: "/src/cursor", branch: "main")
        try ingest([prompt(session: session, at: "2026-09-01T10:00:00Z", "hi")], session: session)

        XCTAssertEqual(try feed(before: "not a time"), [])
        XCTAssertEqual(try feed(before: "").map(\.text), ["hi"], "an empty cursor is no cursor")
    }

    // MARK: - Prompts typed while the agent works

    private func queued(session: String, at timestamp: String, _ text: String, mode: String = "prompt") -> String {
        line(session: session, at: timestamp,
             json: #"{"type":"attachment","attachment":{"type":"queued_command","prompt":"\#(text)","#
                 + #""commandMode":"\#(mode)","origin":{"kind":"human"}}}"#)
    }

    func testAPromptTypedMidTurnTakesItsPlaceInTheFeed() throws {
        let session = try makeSession(cwd: "/src/alpha", branch: "main")
        try ingest([
            prompt(session: session, at: "2026-09-01T10:00:00Z", "start"),
            queued(session: session, at: "2026-09-01T10:00:05Z", "and also this"),
            reply(session: session, at: "2026-09-01T10:00:09Z", "done both")
        ], session: session)

        XCTAssertEqual(try feed().map(\.text), ["done both", "and also this", "start"])
        XCTAssertEqual(try feed(session: session).map(\.text), ["done both", "and also this", "start"])
        XCTAssertEqual(try feed().first(where: { $0.text == "and also this" })?.kind, "prompt")
    }

    func testAMidTurnPromptStaysInItsOwnConversation() throws {
        let first = try makeSession(cwd: "/src/alpha", branch: "main")
        let second = try makeSession(cwd: "/src/beta", branch: "main")
        try ingest([
            queued(session: first, at: "2026-09-01T10:00:05Z", "only alpha")
        ], session: first)
        try ingest([
            prompt(session: second, at: "2026-09-01T10:00:00Z", "beta")
        ], session: second)

        XCTAssertEqual(try feed(session: second).map(\.text), ["beta"])
        XCTAssertEqual(try feed(session: first).map(\.text), ["only alpha"])
    }

    func testAMidTurnPromptOlderThanAFullPageWaitsForTheNextOne() throws {
        let session = try makeSession(cwd: "/src/alpha", branch: "main")
        try ingest([
            queued(session: session, at: "2026-09-01T09:00:00Z", "early"),
            prompt(session: session, at: "2026-09-01T10:00:00Z", "one"),
            prompt(session: session, at: "2026-09-01T10:00:01Z", "two")
        ], session: session)

        let first = try feed(limit: 2)
        XCTAssertEqual(first.map(\.text), ["two", "one"])
        XCTAssertEqual(try feed(limit: 2, before: first.last?.timestamp).map(\.text), ["early"])
    }

    func testAQueuedTaskNotificationIsNotAPrompt() throws {
        // Only what a person typed counts: a queued command the harness queued
        // for itself is not a line of the conversation.
        let session = try makeSession(cwd: "/src/alpha3", branch: "main")
        try ingest([
            prompt(session: session, at: "2026-09-01T10:00:00Z", "start"),
            queued(session: session, at: "2026-09-01T10:00:05Z", "a task finished", mode: "task-notification")
        ], session: session)

        XCTAssertEqual(try feed(work: true).map(\.text), ["start"])
    }

    // MARK: - The work-output filter

    func testNarrationIsNotInTheConversationAtAll() throws {
        // "Reading the query plan." is the agent talking about its own work. A
        // window for watching people and agents talk has no room for it: what a
        // reader wants under their question is the answer.
        let session = try makeSession(cwd: "/src/delta", branch: "main")
        try ingest([
            prompt(session: session, at: "2026-09-01T10:00:00Z", "why is it slow"),
            progress(session: session, at: "2026-09-01T10:00:01Z", "Reading the query plan.")
        ], session: session)

        XCTAssertEqual(try feed().map(\.text), ["why is it slow"])
        XCTAssertEqual(try feed(work: true).map(\.text),
                       ["Reading the query plan.", "why is it slow"],
                       "the filter hides it; it is still there for anyone who asks")
    }

    func testTheQuestionAndItsAnswerLandNextToEachOther() throws {
        // The point of hiding narration: a turn that spent six lines getting
        // there reads as one question and one answer.
        let session = try makeSession(cwd: "/src/delta2", branch: "main")
        try ingest([
            prompt(session: session, at: "2026-09-01T10:00:00Z", "why is it slow"),
            progress(session: session, at: "2026-09-01T10:00:01Z", "Reading the query plan."),
            progress(session: session, at: "2026-09-01T10:00:02Z", "Now the index definitions."),
            reply(session: session, at: "2026-09-01T10:00:03Z", "It was a missing index.")
        ], session: session)

        XCTAssertEqual(try feed().map(\.text), ["It was a missing index.", "why is it slow"])
        XCTAssertEqual(try feed(work: true).map(\.text), [
            "It was a missing index.", "Now the index definitions.",
            "Reading the query plan.", "why is it slow"
        ])
    }

    func testASessionThatHasOnlyNarratedSaysNothingYet() throws {
        // A session mid-turn contributes no row at all. That it is working is a
        // real thing a reader wants to know, and it is not the conversation —
        // whatever surfaces it, it is not a line in here.
        let first = try makeSession(cwd: "/src/nu", branch: "main")
        let second = try makeSession(cwd: "/src/xi", branch: "main")
        try ingest([
            progress(session: first, at: "2026-09-01T10:00:00Z", "first is reading the plan")
        ], session: first)
        try ingest([
            progress(session: second, at: "2026-09-01T10:00:01Z", "second is running tests")
        ], session: second)

        XCTAssertTrue(try feed().isEmpty)
    }

    func testHidingNarrationDoesNotHideWhatCameAfterIt() throws {
        // The filter drops lines, not rows around them: a page whose newest
        // entry is narration still returns the prompt underneath it.
        let session = try makeSession(cwd: "/src/omicron", branch: "main")
        try ingest([
            prompt(session: session, at: "2026-09-01T10:00:00Z", "why is it slow"),
            progress(session: session, at: "2026-09-01T10:00:01Z", "reading the plan")
        ], session: session)

        XCTAssertEqual(try feed().map(\.text), ["why is it slow"])
    }

    func testAskingForMoreThanExistsReturnsWhatExists() throws {
        // The read scans more rows than it returns, because kind is only known
        // after parsing. A transcript with nothing showable in it must still
        // terminate.
        let session = try makeSession(cwd: "/src/epsilon", branch: "main")
        try ingest([
            line(session: session, at: "2026-09-01T10:00:00Z",
                 json: #"{"type":"assistant","message":{"role":"assistant","stop_reason":"tool_use","#
                     + #""content":[{"type":"thinking","thinking":"weighing it"}]}}"#)
        ], session: session)

        XCTAssertTrue(try feed(limit: 500).isEmpty)
    }

    func testASessionAProgramIsDrivingIsNotInTheFeedAtAll() throws {
        // `claude -p` under a script: the "prompt" is the program's 30,000-word
        // instructions and the "reply" is the JSON it asked for. Both sides are
        // machinery, and either one alone fills a window this size.
        let session = try makeSession(cwd: "/src/lambda", branch: "main")
        try ingest([
            line(session: session, at: "2026-09-01T10:00:00Z",
                 json: #"{"type":"user","entrypoint":"sdk-cli","message":{"role":"user","#
                     + #""content":"You are reviewing writing the way a careful editor would."}}"#),
            line(session: session, at: "2026-09-01T10:00:01Z",
                 json: #"{"type":"assistant","entrypoint":"sdk-cli","message":{"role":"assistant","#
                     + #""stop_reason":"end_turn","content":[{"type":"text","text":"[{\"title\":\"x\"}]"}]}}"#),
            prompt(session: session, at: "2026-09-01T10:00:02Z", "and this one I typed")
        ], session: session)

        XCTAssertEqual(try feed(work: true).map(\.text), ["and this one I typed"])
    }

    func testAnEditorIntegrationIsAPersonTyping() throws {
        // The rule keys on the `sdk-` prefix, not on an allow-list, so a new
        // editor front end shows up and a new SDK binding does not.
        let session = try makeSession(cwd: "/src/mu", branch: "main")
        try ingest([
            line(session: session, at: "2026-09-01T10:00:00Z",
                 json: #"{"type":"user","entrypoint":"claude-desktop","message":{"role":"user","#
                     + #""content":"from the desktop app"}}"#)
        ], session: session)

        XCTAssertEqual(try feed().map(\.text), ["from the desktop app"])
    }

    // MARK: - One conversation on its own

    func testNarrowingToASessionReturnsThatSessionAndNothingElse() throws {
        let first = try makeSession(cwd: "/src/rho", branch: "main")
        let second = try makeSession(cwd: "/src/sigma", branch: "main")
        try ingest([
            prompt(session: first, at: "2026-09-01T10:00:00Z", "rho asks"),
            reply(session: first, at: "2026-09-01T10:00:02Z", "rho answers")
        ], session: first)
        try ingest([
            prompt(session: second, at: "2026-09-01T10:00:01Z", "sigma asks")
        ], session: second)

        XCTAssertEqual(try feed(session: first).map(\.text), ["rho answers", "rho asks"])
        XCTAssertEqual(try feed(session: second).map(\.text), ["sigma asks"])
    }

    /// The whole reason the narrowing is a parameter and not a filter over the
    /// merged answer. The merged feed is a *page* — the newest few hundred lines
    /// across every session — so a quiet conversation's share of it is whatever
    /// happens to fit. Sieving that would show a reader a conversation with most
    /// of itself missing; asking the database for it returns it whole.
    func testAQuietSessionComesBackWholeEvenWhenTheMergedPageHasNoneOfIt() throws {
        let quiet = try makeSession(cwd: "/src/tau", branch: "main")
        let loud = try makeSession(cwd: "/src/upsilon", branch: "main")
        try ingest([
            prompt(session: quiet, at: "2026-09-01T10:00:00Z", "quiet asks"),
            reply(session: quiet, at: "2026-09-01T10:00:01Z", "quiet answers")
        ], session: quiet)
        try ingest(
            (0..<40).map { index in
                prompt(session: loud, at: "2026-09-01T11:00:\(String(format: "%02d", index))Z", "loud \(index)")
            }, session: loud)

        let page = try feed(limit: 10)
        XCTAssertFalse(page.contains { $0.sessionId == quiet },
                       "the fixture is wrong: the quiet session has to be off the merged page")
        XCTAssertEqual(try feed(limit: 10, session: quiet).map(\.text),
                       ["quiet answers", "quiet asks"])
    }

    func testANarrowedReadPagesBackwardsTheSameWay() throws {
        // The scoped read takes its order from a different index, so the paging
        // cursor has to keep working across that change — same `before`, same
        // newest-first pages.
        let session = try makeSession(cwd: "/src/phi", branch: "main")
        try ingest([
            prompt(session: session, at: "2026-09-01T10:00:00Z", "one"),
            prompt(session: session, at: "2026-09-01T10:00:01Z", "two"),
            prompt(session: session, at: "2026-09-01T10:00:02Z", "three")
        ], session: session)

        let page = try feed(limit: 2, session: session)
        XCTAssertEqual(page.map(\.text), ["three", "two"])
        let older = try XCTUnwrap(page.last).timestamp
        XCTAssertEqual(try feed(limit: 2, before: older, session: session).map(\.text), ["one"])
    }

    func testAnEmptySessionIdIsTheMergedFeed() throws {
        // The window passes whatever the row carried; a row with no source id is
        // not a request for a conversation called "".
        let session = try makeSession(cwd: "/src/chi", branch: "main")
        try ingest([
            prompt(session: session, at: "2026-09-01T10:00:00Z", "hi")
        ], session: session)

        XCTAssertEqual(try feed(session: "").map(\.text), ["hi"])
    }

    func testTheWorkOutputFilterStillAppliesWhenNarrowed() throws {
        let session = try makeSession(cwd: "/src/psi", branch: "main")
        try ingest([
            prompt(session: session, at: "2026-09-01T10:00:00Z", "why is it slow"),
            progress(session: session, at: "2026-09-01T10:00:01Z", "reading the plan"),
            reply(session: session, at: "2026-09-01T10:00:02Z", "a missing index")
        ], session: session)

        XCTAssertEqual(try feed(session: session).map(\.text),
                       ["a missing index", "why is it slow"])
        XCTAssertEqual(try feed(work: true, session: session).map(\.text),
                       ["a missing index", "reading the plan", "why is it slow"])
    }

    // MARK: - Paging

    func testPagingBackwardsPicksUpWhereThePageEnded() throws {
        let session = try makeSession(cwd: "/src/zeta", branch: "main")
        try ingest([
            prompt(session: session, at: "2026-09-01T10:00:00Z", "one"),
            prompt(session: session, at: "2026-09-01T10:00:01Z", "two"),
            prompt(session: session, at: "2026-09-01T10:00:02Z", "three")
        ], session: session)

        let page = try feed(limit: 2)
        XCTAssertEqual(page.map(\.text), ["three", "two"])
        let older = try XCTUnwrap(page.last).timestamp
        XCTAssertEqual(try feed(limit: 2, before: older).map(\.text), ["one"])
    }

    func testTheLimitIsCountedInLinesNotRows() throws {
        // A thinking block and the text after it come out of one message, so the
        // limit has to be counted in lines, not rows. An entry that is bigger
        // than the limit all by itself still comes back whole — see the
        // mid-entry test below for why half of one is worse than a page that
        // overshoots by a line.
        let session = try makeSession(cwd: "/src/eta", branch: "main")
        try ingest([thinkingThenText(session: session, at: "2026-09-01T10:00:00Z")], session: session)

        XCTAssertEqual(try feed(limit: 1, work: true).count, 2, "the lone entry is not cut in half")
        XCTAssertEqual(try feed(work: true).map(\.kind), ["reply", "thinking"])
    }

    func testIdsAreUniqueAcrossBlocksOfTheSameEntry() throws {
        let session = try makeSession(cwd: "/src/theta", branch: "main")
        try ingest([thinkingThenText(session: session, at: "2026-09-01T10:00:00Z")], session: session)

        let ids = try feed(work: true).map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    /// A block's id is a property of the transcript, not of what the caller
    /// asked to see. Numbering after the filter moved every id whenever the
    /// window's "show work output" toggle moved, and the window read that as a
    /// feed full of brand-new rows.
    func testAnIdDoesNotMoveWhenTheWorkOutputFilterChanges() throws {
        let session = try makeSession(cwd: "/src/iota", branch: "main")
        try ingest([thinkingThenText(session: session, at: "2026-09-01T10:00:00Z")], session: session)

        let shown = try XCTUnwrap(try feed().first)
        let withWork = try XCTUnwrap(try feed(work: true).first { $0.kind == "reply" })
        XCTAssertEqual(shown.id, withWork.id)
    }

    /// An id does not move when more of the transcript arrives either: it is
    /// the message's own row id, which a later read never renumbers.
    func testAnIdDoesNotMoveWhenMoreArrives() throws {
        let session = try makeSession(cwd: "/src/iota2", branch: "main")
        try ingest([prompt(session: session, at: "2026-09-01T10:00:00Z", "first")], session: session)
        let before = try XCTUnwrap(try feed().first)

        try ingest([prompt(session: session, at: "2026-09-01T10:00:01Z", "second")], session: session)
        let after = try XCTUnwrap(try feed().first { $0.text == "first" })
        XCTAssertEqual(before.id, after.id)
    }

    /// The id is `messages.id * 1000 + blockIndex`, so a block index of 1000 is
    /// the next entry's block 0. Capping the blocks *after* the work-output
    /// filter counts only the blocks the caller wanted, so an entry whose
    /// thousandth block is the first one kept sails past the cap and lands on
    /// top of the next entry's identity.
    func testAnEntryLongerThanTheIdStrideCannotCollideWithTheNextOne() throws {
        let session = try makeSession(cwd: "/src/lambda", branch: "main")
        let thinking = (0..<1000)
            .map { #"{"type":"thinking","thinking":"step \#($0)"}"# }
            .joined(separator: ",")
        try ingest([
            line(session: session, at: "2026-09-01T10:00:00Z",
                 json: #"{"type":"assistant","message":{"role":"assistant","stop_reason":"end_turn","#
                     + #""content":[\#(thinking),{"type":"text","text":"go with B"}]}}"#),
            reply(session: session, at: "2026-09-01T10:00:01Z", "and here is why")
        ], session: session)

        let ids = try feed().map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count,
                       "two rows are fighting over one id")
    }

    /// The merged read orders by time; a read narrowed to one session has to
    /// as well, or the same feed reads newest-first in one mode and by
    /// insertion order in the other. They differ whenever a file is imported
    /// out of order or a line is backfilled.
    func testANarrowedReadIsOrderedByTimeNotByInsertion() throws {
        let session = try makeSession(cwd: "/src/mu", branch: "main")
        try ingest([
            prompt(session: session, at: "2026-09-01T10:00:02Z", "asked second"),
            prompt(session: session, at: "2026-09-01T10:00:01Z", "asked first")
        ], session: session)

        let texts = try feed(session: session).map(\.text)
        XCTAssertEqual(texts, ["asked second", "asked first"],
                       "the narrowed read fell back on insertion order")
    }

    /// Pages are cut on the timestamp, and every block of one entry shares one —
    /// so a page that stopped mid-entry didn't defer the rest, it lost it: the
    /// next page asks for older than that same value. The entry has to be
    /// held back whole instead.
    func testAPageEndsOnAnEntryBoundaryAndTheNextPageHasTheWholeEntry() throws {
        let session = try makeSession(cwd: "/src/kappa", branch: "main")
        try ingest([
            thinkingThenText(session: session, at: "2026-09-01T10:00:01Z"),
            prompt(session: session, at: "2026-09-01T10:00:02Z", "newest")
        ], session: session)

        let page = try feed(limit: 2, work: true)
        XCTAssertEqual(page.map(\.text), ["newest"], "the two-line entry is held back whole")

        let older = try XCTUnwrap(page.last).timestamp
        XCTAssertEqual(try feed(limit: 2, work: true, before: older).map(\.text),
                       ["go with B", "weighing it"])
    }
}
