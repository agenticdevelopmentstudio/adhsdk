import XCTest
@testable import AgenticDeveloperHubSDKDatabase

/// Covers reading a session's `custom-title` out of what the Claude pipeline
/// already stored in the event store, instead of re-streaming the `.jsonl`.
///
/// The distinction these pin down is the one that makes the substitution safe:
/// an *authoritative* "this session has no title" (messages are stored, none
/// is a title) must be told apart from "the pipeline hasn't reached this
/// session", because only the first justifies skipping the file. Getting that
/// wrong would silently drop titles rather than merely cost memory.
final class ImportedTitleTests: XCTestCase {

    private var root: URL!
    private var harness: ClaudePipelineTestHarness!
    private var database: DaemonDatabase { harness.database }

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("imported-title-\(UUID().uuidString)", isDirectory: true)
        harness = try ClaudePipelineTestHarness(directory: root)
    }

    override func tearDownWithError() throws {
        harness = nil
        try? FileManager.default.removeItem(at: root)
    }

    // MARK: - Helpers

    private func titleLine(session: String, title: String) -> String {
        #"{"type":"custom-title","customTitle":"\#(title)","sessionId":"\#(session)"}"#
    }

    private func chatterLine(session: String) -> String {
        #"{"type":"assistant","sessionId":"\#(session)","uuid":"\#(UUID().uuidString)","#
            + #""timestamp":"2026-07-30T00:00:00Z","message":{"role":"assistant","content":[]}}"#
    }

    private func ingest(_ lines: [String], session: String) throws {
        try harness.ingestTranscript(lines: lines, file: harness.transcriptFile(sessionId: session))
    }

    // MARK: - Tests

    func testReturnsTheLatestTitleWhenSeveralWereSet() throws {
        let session = UUID().uuidString
        try ingest([
            titleLine(session: session, title: "first"),
            chatterLine(session: session),
            titleLine(session: session, title: "renamed"),
            chatterLine(session: session)
        ], session: session)

        // "Latest" must match what a whole-file scan returned: the LAST occurrence,
        // not the first — a session retitled mid-run keeps its newest name.
        XCTAssertEqual(try database.latestCustomTitle(sessionId: session), .found("renamed"))
    }

    func testATitleCapturedByALaterReadIsTheLatest() throws {
        // Title lines carry no timestamp. A rename appended after the file was
        // first read is captured later, so it is the newer title even though
        // neither line says when it was written.
        let session = UUID().uuidString
        try ingest([titleLine(session: session, title: "first"), chatterLine(session: session)], session: session)
        try ingest([titleLine(session: session, title: "renamed")], session: session)

        XCTAssertEqual(try database.latestCustomTitle(sessionId: session), .found("renamed"))
    }

    func testStoredMessagesWithNoTitleAreAuthoritativelyAbsent() throws {
        let session = UUID().uuidString
        try ingest([chatterLine(session: session), chatterLine(session: session)], session: session)

        // `.absent`, not `.notImported`: this is what lets the startup pass stop
        // re-reading a large transcript that will never yield a title.
        XCTAssertEqual(try database.latestCustomTitle(sessionId: session), .absent)
    }

    func testUnknownSessionIsNotImportedRatherThanAbsent() throws {
        // No rows at all — the DB cannot answer, so the caller must fall back to
        // the file. Reporting `.absent` here would silently lose real titles.
        XCTAssertEqual(try database.latestCustomTitle(sessionId: UUID().uuidString), .notImported)
    }

    func testWithoutAnEventStoreNothingIsImported() throws {
        // A session database with no event store attached cannot answer at all.
        let made = try TestDaemonDatabase.makeSessionDatabase()
        defer { TestDaemonDatabase.remove(path: made.path) }
        XCTAssertEqual(try made.db.latestCustomTitle(sessionId: "s1"), .notImported)
    }

    func testTitlesAreScopedToTheirOwnSession() throws {
        let mine = UUID().uuidString
        let theirs = UUID().uuidString
        try ingest([titleLine(session: theirs, title: "not mine"), chatterLine(session: theirs)], session: theirs)
        try ingest([chatterLine(session: mine)], session: mine)

        XCTAssertEqual(try database.latestCustomTitle(sessionId: mine), .absent)
        XCTAssertEqual(try database.latestCustomTitle(sessionId: theirs), .found("not mine"))
    }

    func testAMalformedTitleLineReadsAsAbsentNotAsACrash() throws {
        let session = UUID().uuidString
        try ingest([chatterLine(session: session)], session: session)
        // A line that is not JSON at all is quarantined by the pipeline, not stored.
        let file = harness.transcriptFile(sessionId: session)
        try? harness.ingestTranscript(lines: ["{not json at all"], file: file)

        // Same tolerance the file-scanning path has: a line it can't decode is
        // skipped, and the session still counts as imported.
        XCTAssertEqual(try database.latestCustomTitle(sessionId: session), .absent)
    }

    func testAnEmptyTitleIsNotTreatedAsATitle() throws {
        let session = UUID().uuidString
        try ingest([titleLine(session: session, title: ""), chatterLine(session: session)], session: session)

        // `enrich` only writes non-empty summaries; surfacing "" as `.found`
        // would make the caller overwrite a good summary with nothing.
        XCTAssertEqual(try database.latestCustomTitle(sessionId: session), .absent)
    }

    func testASessionWithOnlyAnUnusableTitleIsNotImported() throws {
        // An empty title stores nothing at all — no event, no message — so the
        // store cannot tell this session from one it never saw, and the caller
        // falls back to the file (which finds no title either).
        let session = UUID().uuidString
        try ingest([titleLine(session: session, title: "")], session: session)

        XCTAssertEqual(try database.latestCustomTitle(sessionId: session), .notImported)
    }

    func testAnUnusableLastTitleFallsBackToTheLastUsableOne() throws {
        let session = UUID().uuidString
        try ingest([
            titleLine(session: session, title: "keep me"),
            titleLine(session: session, title: ""),
            chatterLine(session: session)
        ], session: session)
        try? harness.ingestTranscript(lines: ["{not json at all"], file: harness.transcriptFile(sessionId: session))

        // The file scan takes the last line that *parses to a non-empty title* and
        // skips the rest, so stopping at the last `custom-title` line full stop
        // would report `.absent` here — which the enricher trusts as authoritative
        // and writes no summary, losing a title the file scan finds.
        XCTAssertEqual(try database.latestCustomTitle(sessionId: session), .found("keep me"))
    }

    func testRawJSONParsingExtractsTheTitleField() {
        XCTAssertEqual(
            DaemonDatabase.customTitle(fromRawJSON: #"{"type":"custom-title","customTitle":"hello"}"#),
            "hello"
        )
        XCTAssertNil(DaemonDatabase.customTitle(fromRawJSON: #"{"type":"custom-title"}"#))
        XCTAssertNil(DaemonDatabase.customTitle(fromRawJSON: "garbage"))
    }
}
