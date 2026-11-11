import AgenticDeveloperHubSDKCore
import Foundation
import XCTest
@testable import AgenticDeveloperHubSDKDatabase

/// The Claude ingest sources against temp directories and a real spool: drop-directory
/// hook files, the HTTP/socket capture record, and transcript byte cursors.
/// What a drop source reported through `onUnreadable`, in order.
private final class ReportedDrops: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: [(name: String, reason: String)] = []
    var entries: [(name: String, reason: String)] { lock.withLock { stored } }
    func append(_ name: String, _ reason: String) { lock.withLock { stored.append((name, reason)) } }
}

final class ClaudeSourcesTests: XCTestCase {

    private var tmpDir: URL!
    private var dropDir: URL!
    private var projectsDir: URL!
    private var spool: ProviderSpool!

    override func setUpWithError() throws {
        let suffix = String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(6))
        tmpDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("sten-claude-src-\(suffix)")
        dropDir = tmpDir.appendingPathComponent("drop")
        projectsDir = tmpDir.appendingPathComponent("projects")
        for dir in [dropDir!, projectsDir!] {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        spool = try ProviderSpool(
            path: tmpDir.appendingPathComponent(ProviderSpool.fileName(provider: ClaudeProvider.name)).path,
            provider: ClaudeProvider.name)
    }

    override func tearDownWithError() throws {
        spool = nil
        // Restore permissions so a chmod-000 fixture can be removed.
        if let items = FileManager.default.enumerator(atPath: tmpDir.path) {
            for case let item as String in items {
                try? FileManager.default.setAttributes(
                    [.posixPermissions: 0o644], ofItemAtPath: tmpDir.appendingPathComponent(item).path)
            }
        }
        try? FileManager.default.removeItem(at: tmpDir)
    }

    // MARK: - Helpers

    private static let hookFixtures = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().appendingPathComponent("Fixtures/hooks")

    private static func hookFixture(_ name: String) throws -> Data {
        try Data(contentsOf: hookFixtures.appendingPathComponent("\(name).json"))
    }

    private struct Crash: Error {}

    /// Counts and optionally throws at the hooks, for crash and batching tests.
    private final class Probe: @unchecked Sendable {
        private let lock = NSLock()
        private var counts: [SourceStep: Int] = [:]
        private let throwAt: SourceStep?
        init(throwAt: SourceStep? = nil) { self.throwAt = throwAt }
        func fire(_ step: SourceStep) throws {
            lock.lock()
            counts[step, default: 0] += 1
            lock.unlock()
            if step == throwAt { throw Crash() }
        }
        func count(_ step: SourceStep) -> Int {
            lock.lock()
            defer { lock.unlock() }
            return counts[step, default: 0]
        }
    }

    @discardableResult
    private func writeDrop(_ name: String, _ data: Data, age: TimeInterval = 60) throws -> URL {
        let url = dropDir.appendingPathComponent(name)
        try data.write(to: url)
        try setMTime(url, Date().addingTimeInterval(-age))
        return url
    }

    private func setMTime(_ url: URL, _ date: Date) throws {
        try FileManager.default.setAttributes([.modificationDate: date], ofItemAtPath: url.path)
    }

    private func mtime(_ url: URL) throws -> Date {
        try XCTUnwrap(try FileManager.default.attributesOfItem(atPath: url.path)[.modificationDate] as? Date)
    }

    private func pending() throws -> [RawRecord] {
        let count = try spool.pendingCount()
        return try spool.pendingBatch(limit: max(1, count), maxBytes: Int.max).map(\.record)
    }

    private func exists(_ url: URL) -> Bool { FileManager.default.fileExists(atPath: url.path) }

    /// A drainer over the test spool, with its own archive and store.
    private func makeDrainer() throws -> (PipelineDrainer, RawArchive) {
        let archive = try RawArchive(
            path: tmpDir.appendingPathComponent(RawArchive.fileName(provider: ClaudeProvider.name)).path,
            provider: ClaudeProvider.name)
        let store = try EventStore(path: tmpDir.appendingPathComponent(EventStore.fileName).path)
        let drainer = try PipelineDrainer(spool: spool, archive: archive, normalizer: ClaudeNormalizer(), store: store)
        return (drainer, archive)
    }

    // MARK: - Hook drop directory

    func testDropFilesAreAppendedInNameOrderThenDeleted() throws {
        let second = try writeDrop("1793361609000-bbbbbbbb.json", try Self.hookFixture("PreToolUse"))
        let first = try writeDrop("1793361600000-aaaaaaaa.json", try Self.hookFixture("SessionStart"))
        let quarantined = try writeDrop("error-1793361500000-cccccccc.json", try Self.hookFixture("Stop"))
        let inFlight = try writeDrop("1793361610000-dddddddd.json.tmp", try Self.hookFixture("Stop"))
        let firstMTime = try mtime(first)

        let source = ClaudeHookDropSource(dropDirectory: dropDir)
        XCTAssertEqual(source.provider, ClaudeProvider.name)
        XCTAssertEqual(try source.poll(into: spool), 2)

        let records = try pending()
        XCTAssertEqual(records.map(\.dedupKey), ["1793361600000-aaaaaaaa", "1793361609000-bbbbbbbb"])
        XCTAssertEqual(records.map(\.sourceKind), [ClaudeProvider.hookKind, ClaudeProvider.hookKind])
        XCTAssertEqual(records[0].payload, try Self.hookFixture("SessionStart"))
        XCTAssertEqual(records[1].payload, try Self.hookFixture("PreToolUse"))
        XCTAssertEqual(records[0].receivedAt.timeIntervalSince1970, firstMTime.timeIntervalSince1970, accuracy: 1e-3)
        XCTAssertFalse(exists(first))
        XCTAssertFalse(exists(second))
        XCTAssertTrue(exists(quarantined), "error- files are not drop input")
        XCTAssertTrue(exists(inFlight), "a .json.tmp is still being written")
        XCTAssertEqual(try source.poll(into: spool), 0)
    }

    func testDropFileYoungerThanMinimumAgeIsLeftAlone() throws {
        let young = try writeDrop("1793361600000-aaaaaaaa.json", try Self.hookFixture("Stop"), age: 0)
        let source = ClaudeHookDropSource(dropDirectory: dropDir, minimumAge: 30)
        XCTAssertEqual(try source.poll(into: spool), 0)
        XCTAssertTrue(exists(young))
        XCTAssertEqual(try spool.pendingCount(), 0)

        try setMTime(young, Date().addingTimeInterval(-31))
        XCTAssertEqual(try source.poll(into: spool), 1)
        XCTAssertFalse(exists(young))
    }

    func testUnreadableDropFileMovesToErrorsAndIsNotAppended() throws {
        let unreadable = try writeDrop("1793361600000-aaaaaaaa.json", try Self.hookFixture("Stop"))
        try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: unreadable.path)
        try XCTSkipIf(FileManager.default.isReadableFile(atPath: unreadable.path), "running with read override")
        try writeDrop("1793361601000-bbbbbbbb.json", try Self.hookFixture("PreToolUse"))

        let reported = ReportedDrops()
        let source = ClaudeHookDropSource(dropDirectory: dropDir) { moved, reason in
            reported.append(moved.lastPathComponent, reason)
        }
        XCTAssertEqual(try source.poll(into: spool), 1)
        XCTAssertFalse(exists(unreadable))
        let moved = dropDir.appendingPathComponent("errors/error-1793361600000-aaaaaaaa.json")
        XCTAssertTrue(exists(moved))
        XCTAssertEqual(try pending().map(\.dedupKey), ["1793361601000-bbbbbbbb"])
        let entries = reported.entries
        XCTAssertEqual(entries.map(\.name), ["error-1793361600000-aaaaaaaa.json"])
        XCTAssertTrue(entries.first?.reason.hasPrefix("unreadable drop file: ") ?? false, "\(entries)")
    }

    /// An empty or whitespace-only drop file is still appended, and its name is
    /// reported as a lost event; a file with content is not.
    func testAnEmptyDropFileIsAppendedAndReportedLost() throws {
        try writeDrop("1793361600000-aaaaaaaa.json", Data())
        try writeDrop("1793361601000-bbbbbbbb.json", Data(" \n".utf8))
        try writeDrop("1793361602000-cccccccc.json", try Self.hookFixture("Stop"))

        let reported = ReportedDrops()
        let source = ClaudeHookDropSource(dropDirectory: dropDir, onLost: { name in
            reported.append(name, "lost")
        })
        XCTAssertEqual(try source.poll(into: spool), 3)
        XCTAssertEqual(reported.entries.map(\.name),
                       ["1793361600000-aaaaaaaa.json", "1793361601000-bbbbbbbb.json"])
    }

    /// Review Focus 4: no `session_id`, an empty body and invalid JSON are all archived
    /// (the backup keeps everything); only the invalid JSON is quarantined, bytes intact.
    func testMalformedDropFilesAreArchivedAndInvalidJSONIsQuarantined() throws {
        try writeDrop("1793361600000-aaaaaaaa.json", try Self.hookFixture("no-session-id"))
        try writeDrop("1793361601000-bbbbbbbb.json", Data())
        let invalid = try Self.hookFixture("invalid-json")
        try writeDrop("1793361602000-cccccccc.json", invalid)

        XCTAssertEqual(try ClaudeHookDropSource(dropDirectory: dropDir).poll(into: spool), 3)
        let (drainer, archive) = try makeDrainer()
        // A record the normalizer rejects is charged one attempt per pass and
        // quarantined when its attempts run out.
        for _ in 0..<ProviderSpool.maxAttempts where try spool.pendingCount() > 0 {
            _ = drainer.drainUntilEmpty()
        }

        XCTAssertEqual(try archive.count(), 3)
        XCTAssertEqual(try spool.pendingCount(), 0)
        let quarantined = try spool.quarantined(limit: 10)
        XCTAssertEqual(quarantined.map(\.record.dedupKey), ["1793361602000-cccccccc"])
        XCTAssertEqual(quarantined.first?.record.payload, invalid)
    }

    func testCrashAfterAppendRedeliversTheSameKeysAsArchiveDuplicates() throws {
        let names = ["1793361600000-aaaaaaaa", "1793361601000-bbbbbbbb"]
        try writeDrop("\(names[0]).json", try Self.hookFixture("SessionStart"))
        try writeDrop("\(names[1]).json", try Self.hookFixture("PreToolUse"))

        let probe = Probe(throwAt: .afterAppend)
        let crashing = ClaudeHookDropSource(dropDirectory: dropDir, faultInjector: { try probe.fire($0) })
        XCTAssertThrowsError(try crashing.poll(into: spool))
        XCTAssertEqual(try pending().map(\.dedupKey), names, "the append committed")
        for name in names { XCTAssertTrue(exists(dropDir.appendingPathComponent("\(name).json")), "delete skipped") }

        let (drainer, archive) = try makeDrainer()
        _ = drainer.drainUntilEmpty()
        XCTAssertEqual(try archive.count(), 2)

        XCTAssertEqual(try ClaudeHookDropSource(dropDirectory: dropDir).poll(into: spool), 2)
        let redelivered = try pending()
        XCTAssertEqual(redelivered.map(\.dedupKey), names)
        for outcome in try archive.append(redelivered).outcomes {
            guard case .duplicate = outcome else { return XCTFail("expected duplicate, got \(outcome)") }
        }
        _ = drainer.drainUntilEmpty()
        XCTAssertEqual(try archive.count(), 2, "no double row after a drain")
        XCTAssertEqual(try spool.pendingCount(), 0)
        XCTAssertEqual(try spool.quarantined(limit: 10).count, 0)
        for name in names { XCTAssertFalse(exists(dropDir.appendingPathComponent("\(name).json"))) }
    }

    func testFailedAppendRethrowsAndDeletesNothing() throws {
        let file = try writeDrop("1793361600000-aaaaaaaa.json", try Self.hookFixture("Stop"))
        let probe = Probe(throwAt: .beforeAppend)
        let failing = ClaudeHookDropSource(dropDirectory: dropDir, faultInjector: { try probe.fire($0) })
        XCTAssertThrowsError(try failing.poll(into: spool)) { XCTAssertTrue($0 is Crash) }
        XCTAssertTrue(exists(file))
        XCTAssertEqual(try spool.pendingCount(), 0)
    }

    func testDropFilesAppendInBatchesOfAtMost200() throws {
        let payload = try Self.hookFixture("Stop")
        for index in 0..<450 {
            try writeDrop(String(format: "17933616%05d-%08x.json", index, index), payload)
        }
        let probe = Probe()
        let source = ClaudeHookDropSource(dropDirectory: dropDir, faultInjector: { try probe.fire($0) })
        XCTAssertEqual(try source.poll(into: spool), 450)
        XCTAssertEqual(probe.count(.afterAppend), 3)
        XCTAssertEqual(try spool.pendingCount(), 450)
        let left = try FileManager.default.contentsOfDirectory(atPath: dropDir.path).filter { $0.hasSuffix(".json") }
        XCTAssertEqual(left, [])
    }

    // MARK: - Capture

    func testCaptureRecordCarriesTheEnvelopeUnderAFreshKey() throws {
        let event = ParsedEvent(
            eventType: "PreToolUse", timestamp: "2026-10-30T12:00:09Z",
            hookData: ["session_id": "s1", "tool_name": "Bash"], context: ["process": ["ppid": 1]],
            accountEmail: "dev@example.com", oauthAccountEmail: "")
        let now = Date(timeIntervalSince1970: 1_793_361_609)
        let record = try ClaudeCapture.record(for: event, now: now)
        let again = try ClaudeCapture.record(for: event, now: now)

        XCTAssertEqual(record.provider, ClaudeProvider.name)
        XCTAssertEqual(record.sourceKind, ClaudeProvider.legacyHookKind)
        XCTAssertEqual(record.receivedAt, now)
        XCTAssertTrue(record.dedupKey.hasPrefix("cap-"))
        XCTAssertNotNil(UUID(uuidString: String(record.dedupKey.dropFirst(4))))
        XCTAssertNotEqual(record.dedupKey, again.dedupKey, "every capture is its own delivery")
        let decoded = try JSONSerialization.jsonObject(with: record.payload) as? NSDictionary
        let expected = try JSONSerialization.jsonObject(with: try event.envelopeJSON()) as? NSDictionary
        XCTAssertEqual(decoded, expected)
    }

    // MARK: - Transcripts

    private static let sessionID = "6f1c2a9e-0b7d-4c55-9a3e-2d8f1e4b7a10"

    private static func userLine(_ index: Int, session: String = sessionID) -> String {
        """
        {"type":"user","sessionId":"\(session)","uuid":"00000000-0000-4000-8000-\(String(format: "%012d", index))",\
        "timestamp":"2026-10-30T12:00:\(String(format: "%02d", index % 60)).000Z","cwd":"/Users/dev/work/myapp",\
        "message":{"role":"user","content":"prompt \(index)"}}
        """
    }

    @discardableResult
    private func transcript(_ name: String, lines: [String], trailing: String = "", mtime: Date? = nil) throws -> URL {
        let dir = projectsDir.appendingPathComponent("-Users-dev-work-myapp")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("\(name).jsonl")
        try Data((lines.map { $0 + "\n" }.joined() + trailing).utf8).write(to: url)
        if let mtime { try setMTime(url, mtime) }
        return url
    }

    private func appendText(_ text: String, to url: URL, mtime: Date? = nil) throws {
        let handle = try FileHandle(forWritingTo: url)
        try handle.seekToEnd()
        try handle.write(contentsOf: Data(text.utf8))
        try handle.close()
        if let mtime { try setMTime(url, mtime) }
    }

    private func payloads() throws -> [ClaudeTranscriptPayload] {
        try pending().map { try ClaudeTranscriptPayload.decode($0.payload) }
    }

    private func inode(_ url: URL) throws -> UInt64 {
        try XCTUnwrap((try FileManager.default.attributesOfItem(atPath: url.path)[.systemFileNumber] as? NSNumber)?
            .uint64Value)
    }

    private let base = Date(timeIntervalSince1970: 1_793_361_600)

    func testFirstPollArchivesCompleteLinesAndWithholdsATornTrailingLine() throws {
        let lines = (1...3).map { Self.userLine($0) }
        let torn = Self.userLine(4)
        let url = try transcript(Self.sessionID, lines: lines, trailing: String(torn.prefix(40)), mtime: base)

        let source = ClaudeTranscriptSource(projectsDirectory: projectsDir, linesPerChunk: 2)
        XCTAssertEqual(source.provider, ClaudeProvider.name)
        XCTAssertEqual(try source.poll(into: spool), 3)
        let first = try payloads()
        XCTAssertEqual(first.map(\.line), lines)
        XCTAssertEqual(first.map(\.lineNo), [1, 2, 3])
        XCTAssertEqual(Set(first.map(\.subagentFile)), [false])
        let records = try pending()
        XCTAssertEqual(Set(records.map(\.sourceKind)), [ClaudeProvider.transcriptKind])
        // Each line's offset: the bytes of every line (and newline) before it.
        let offsets = lines.indices.map { index in Int64(lines[..<index].map { $0.utf8.count + 1 }.reduce(0, +)) }
        XCTAssertEqual(first.map(\.byteOffset), offsets)
        XCTAssertEqual(records.map(\.dedupKey), first.map {
            ClaudeTranscriptPayload.dedupKey(line: $0.line, file: $0.file, byteOffset: $0.byteOffset ?? -1)
        })

        // The cursor stops before the torn line.
        let key = ClaudeTranscriptSource.cursorKey(for: url)
        let cursor = try XCTUnwrap(try spool.sourceState(key))
        let object = try XCTUnwrap(try JSONSerialization.jsonObject(with: cursor) as? [String: Any])
        XCTAssertEqual(object["byte_offset"] as? Int, lines.map { $0.utf8.count + 1 }.reduce(0, +))
        XCTAssertEqual(object["line_no"] as? Int, 3)
        XCTAssertEqual(object["inode"] as? UInt64, try inode(url))
        XCTAssertNotNil(object["head_hash"] as? String)
        XCTAssertNotNil(object["file_size"] as? Int)

        // Claude finishes the line.
        try appendText(String(torn.dropFirst(40)) + "\n", to: url, mtime: base.addingTimeInterval(10))
        XCTAssertEqual(try source.poll(into: spool), 1)
        let last = try XCTUnwrap(try payloads().last)
        XCTAssertEqual(last.line, torn)
        XCTAssertEqual(last.lineNo, 4)
    }

    func testAppendArchivesOnlyTheNewLines() throws {
        let url = try transcript(Self.sessionID, lines: [Self.userLine(1), Self.userLine(2)], mtime: base)
        let source = ClaudeTranscriptSource(projectsDirectory: projectsDir)
        XCTAssertEqual(try source.poll(into: spool), 2)
        // Blank lines consume bytes without a line number.
        try appendText("\n\n" + Self.userLine(3) + "\n", to: url, mtime: base.addingTimeInterval(5))
        XCTAssertEqual(try source.poll(into: spool), 1)
        XCTAssertEqual(try payloads().map(\.lineNo), [1, 2, 3])
        try appendText(Self.userLine(4) + "\n", to: url, mtime: base.addingTimeInterval(6))
        XCTAssertEqual(try source.poll(into: spool), 1)
        XCTAssertEqual(try payloads().map(\.line).last, Self.userLine(4))
        XCTAssertEqual(try payloads().map(\.lineNo), [1, 2, 3, 4])
        XCTAssertEqual(try source.poll(into: spool), 0)
    }

    /// Review Focus 2: a rewrite with a new inode restarts at byte 0, and the dedup
    /// keys keep the unchanged lines out of the archive.
    func testRewriteWithNewInodeRestartsWithoutNewArchiveRows() throws {
        let lines = (1...3).map { Self.userLine($0) }
        let url = try transcript(Self.sessionID, lines: lines, mtime: base)
        let source = ClaudeTranscriptSource(projectsDirectory: projectsDir)
        XCTAssertEqual(try source.poll(into: spool), 3)
        let (drainer, archive) = try makeDrainer()
        _ = drainer.drainUntilEmpty()
        XCTAssertEqual(try archive.count(), 3)

        let oldInode = try inode(url)
        try Data((lines + [Self.userLine(4)]).map { $0 + "\n" }.joined().utf8).write(to: url, options: .atomic)
        try setMTime(url, base.addingTimeInterval(20))
        XCTAssertNotEqual(try inode(url), oldInode)

        XCTAssertEqual(try source.poll(into: spool), 4, "restarted from byte 0")
        _ = drainer.drainUntilEmpty()
        XCTAssertEqual(try archive.count(), 4, "only the new line is a new archive row")
        XCTAssertEqual(try spool.quarantined(limit: 10).count, 0)
    }

    /// Review Focus 2: a compaction removes the top line, so every surviving line comes
    /// back at a new offset. Records are keyed by position, so each is archived again
    /// there; the lines keep their own hash in the key, so a different line now at an
    /// offset an earlier one held never collides with it. Nothing conflicts or is
    /// quarantined, and the first-read records stay as they were.
    func testCompactionMovingLinesArchivesThemAgainWithoutConflicts() throws {
        let lines = (1...4).map { Self.userLine($0) }
        let url = try transcript(Self.sessionID, lines: lines, mtime: base)
        let source = ClaudeTranscriptSource(projectsDirectory: projectsDir)
        XCTAssertEqual(try source.poll(into: spool), 4)
        let (drainer, archive) = try makeDrainer()
        _ = drainer.drainUntilEmpty()
        XCTAssertEqual(try archive.count(), 4)
        let line2Key = ClaudeTranscriptPayload.dedupKey(
            line: lines[1], file: url.path, byteOffset: Int64(lines[0].utf8.count + 1))
        let line2Before = try XCTUnwrap(try archive.id(forDedupKey: line2Key))

        let oldInode = try inode(url)
        let compacted = Array(lines.dropFirst()) + [Self.userLine(5)]
        try Data(compacted.map { $0 + "\n" }.joined().utf8).write(to: url, options: .atomic)
        try setMTime(url, base.addingTimeInterval(20))
        XCTAssertNotEqual(try inode(url), oldInode)

        XCTAssertEqual(try source.poll(into: spool), 4, "restarted from byte 0")
        XCTAssertEqual(try payloads().map(\.lineNo), [1, 2, 3, 4], "every surviving line moved up one")
        let outcome = drainer.drainUntilEmpty()
        XCTAssertFalse(outcome.failed, outcome.failureReason ?? "")
        XCTAssertEqual(outcome.quarantined, 0)
        XCTAssertEqual(try spool.quarantined(limit: 10).count, 0, "no conflicts")
        XCTAssertEqual(outcome.conflictCopies, 0, "a new line at an old offset has its own key")
        XCTAssertEqual(try spool.pendingCount(), 0)
        XCTAssertEqual(try archive.count(), 8, "the three moved lines again at their new offsets, plus line 5")
        let kept = try XCTUnwrap(try archive.record(id: line2Before))
        XCTAssertEqual(try ClaudeTranscriptPayload.decode(kept.record.payload).lineNo, 2,
                       "the archive keeps the first-read payload")
    }

    func testClaudeEquivalenceComparesTranscriptLinesOnlyAndHooksByBytes() throws {
        let normalizer = ClaudeNormalizer()
        func transcriptRecord(_ payload: ClaudeTranscriptPayload) throws -> RawRecord {
            RawRecord(provider: ClaudeProvider.name, sourceKind: ClaudeProvider.transcriptKind,
                      dedupKey: ClaudeTranscriptPayload.dedupKey(
                          line: payload.line, file: payload.file, byteOffset: payload.byteOffset ?? 0),
                      receivedAt: base, payload: try ClaudeTranscriptPayload.encode(payload))
        }
        let line = Self.userLine(1)
        let archived = try transcriptRecord(.init(file: "/p/a.jsonl", lineNo: 1, subagentFile: false, line: line))
        let moved = try transcriptRecord(.init(file: "/p/b.jsonl", lineNo: 9, subagentFile: true, line: line))
        let other = try transcriptRecord(.init(file: "/p/a.jsonl", lineNo: 1, subagentFile: false,
                                               line: Self.userLine(2)))
        XCTAssertTrue(normalizer.isEquivalent(archived: archived, incoming: moved))
        XCTAssertFalse(normalizer.isEquivalent(archived: archived, incoming: other))

        func hook(_ text: String) -> RawRecord {
            RawRecord(provider: ClaudeProvider.name, sourceKind: ClaudeProvider.hookKind, dedupKey: "h",
                      receivedAt: base, payload: Data(text.utf8))
        }
        XCTAssertTrue(normalizer.isEquivalent(archived: hook("{\"a\":1}"), incoming: hook("{\"a\":1}")))
        XCTAssertFalse(normalizer.isEquivalent(archived: hook("{\"a\":1}"), incoming: hook("{\"a\": 1}")))
    }

    func testSameInodeChangeBelowTheCursorRestarts() throws {
        let url = try transcript(Self.sessionID, lines: [Self.userLine(1), Self.userLine(2)], mtime: base)
        let source = ClaudeTranscriptSource(projectsDirectory: projectsDir)
        XCTAssertEqual(try source.poll(into: spool), 2)
        let oldInode = try inode(url)
        // Same length, same inode, different bytes: only the head hash notices.
        let handle = try FileHandle(forWritingTo: url)
        try handle.write(contentsOf: Data((Self.userLine(7) + "\n" + Self.userLine(8) + "\n").utf8))
        try handle.close()
        try setMTime(url, base.addingTimeInterval(5))
        XCTAssertEqual(try inode(url), oldInode)
        XCTAssertEqual(try source.poll(into: spool), 2)
        XCTAssertEqual(try payloads().suffix(2).map(\.line), [Self.userLine(7), Self.userLine(8)])
    }

    func testTruncationRestartsFromZero() throws {
        let url = try transcript(Self.sessionID, lines: (1...3).map { Self.userLine($0) }, mtime: base)
        let source = ClaudeTranscriptSource(projectsDirectory: projectsDir)
        XCTAssertEqual(try source.poll(into: spool), 3)
        let (drainer, archive) = try makeDrainer()
        _ = drainer.drainUntilEmpty()

        let handle = try FileHandle(forWritingTo: url)
        try handle.truncate(atOffset: UInt64(Self.userLine(1).utf8.count + 1))
        try handle.close()
        try setMTime(url, base.addingTimeInterval(5))
        XCTAssertEqual(try source.poll(into: spool), 1, "line 1 re-read from byte 0")
        XCTAssertEqual(try payloads().last?.lineNo, 1)
        _ = drainer.drainUntilEmpty()
        XCTAssertEqual(try archive.count(), 3)
    }

    func testWatermarkSkipsUntouchedFiles() throws {
        let untouched = try transcript("aaaaaaaa-0000-4000-8000-000000000001",
                                       lines: [Self.userLine(1, session: "a")], mtime: base)
        let touched = try transcript("bbbbbbbb-0000-4000-8000-000000000002",
                                     lines: [Self.userLine(2, session: "b")], mtime: base.addingTimeInterval(1))
        let source = ClaudeTranscriptSource(projectsDirectory: projectsDir)
        XCTAssertEqual(try source.poll(into: spool), 2)
        XCTAssertNotNil(try spool.sourceState(ClaudeTranscriptSource.watermarkKey))

        // A garbage cursor would re-read the whole file — if the file were visited.
        try spool.setSourceState(ClaudeTranscriptSource.cursorKey(for: untouched), Data("garbage".utf8))
        try appendText(Self.userLine(3, session: "b") + "\n", to: touched, mtime: base.addingTimeInterval(2))
        XCTAssertEqual(try source.poll(into: spool), 1, "only the touched file is read")
        XCTAssertEqual(try payloads().last?.line, Self.userLine(3, session: "b"))

        try setMTime(untouched, base.addingTimeInterval(3))
        XCTAssertEqual(try source.poll(into: spool), 1, "touched again: garbage cursor → restart at 0")
    }

    func testFilesPerPollTakesEveryFileAtTheBoundaryMTime() throws {
        let mtimes = [0, 1, 1, 1, 2].map { base.addingTimeInterval(TimeInterval($0)) }
        for (index, date) in mtimes.enumerated() {
            try transcript("f\(index)", lines: [Self.userLine(index, session: "s\(index)")], mtime: date)
        }
        let source = ClaudeTranscriptSource(projectsDirectory: projectsDir, filesPerPoll: 2)
        XCTAssertEqual(try source.poll(into: spool), 4, "oldest two, plus every file sharing the boundary mtime")
        XCTAssertEqual(try source.poll(into: spool), 1)
        XCTAssertEqual(try source.poll(into: spool), 0)
        XCTAssertEqual(Set(try payloads().map(\.lineNo)), [1])
        XCTAssertEqual(try pending().count, 5)
    }

    func testPollFileHandlesExactlyThatFile() throws {
        let target = try transcript("aaaaaaaa", lines: [Self.userLine(1), Self.userLine(2)], mtime: base)
        let other = try transcript("bbbbbbbb", lines: [Self.userLine(3)], mtime: base)
        let source = ClaudeTranscriptSource(projectsDirectory: projectsDir)
        XCTAssertEqual(try source.poll(file: target, into: spool), 2)
        XCTAssertEqual(Set(try payloads().map(\.file)), [try XCTUnwrap(target.resolvingCanonicalPath)])
        XCTAssertNil(try spool.sourceState(ClaudeTranscriptSource.cursorKey(for: other)))
        XCTAssertNil(try spool.sourceState(ClaudeTranscriptSource.watermarkKey), "a tail never moves the watermark")
        XCTAssertEqual(try source.poll(file: target, into: spool), 0)
        // The sweep shares the tail's cursor, so it reads only the other file.
        XCTAssertEqual(try source.poll(into: spool), 1)
    }

    func testSubagentFilesAreMarked() throws {
        let dir = projectsDir.appendingPathComponent("-Users-dev-work-myapp/\(Self.sessionID)/subagents")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try Data((Self.userLine(1) + "\n").utf8).write(to: dir.appendingPathComponent("agent-a1.jsonl"))
        XCTAssertEqual(try ClaudeTranscriptSource(projectsDirectory: projectsDir).poll(into: spool), 1)
        XCTAssertEqual(try payloads().map(\.subagentFile), [true])
    }

    /// The step-2 source contract: crash before and after an append, recover with a
    /// fresh source, and spool exactly what an uninterrupted run spools.
    func testTranscriptSourceConformsToTheSourceContract() throws {
        for index in 0..<3 {
            try transcript("c\(index)", lines: (1...5).map { Self.userLine(index * 10 + $0, session: "c\(index)") },
                           mtime: base.addingTimeInterval(TimeInterval(index)))
        }
        // A line Claude wrote twice verbatim: two offsets, so two dedup keys.
        let repeated = Self.userLine(90, session: "c-repeat")
        try transcript("c-repeat", lines: [repeated, Self.userLine(91, session: "c-repeat"), repeated],
                       mtime: base.addingTimeInterval(5))
        let projects = projectsDir!
        let makeSource: ((@Sendable (SourceStep) throws -> Void)?) throws -> any IngestSource = { injector in
            ClaudeTranscriptSource(projectsDirectory: projects, filesPerPoll: 1, linesPerChunk: 2,
                                   faultInjector: injector)
        }
        let failures = try ProviderConformance.checkSource(
            provider: ClaudeProvider.name, workDirectory: tmpDir,
            equivalent: ClaudeNormalizer().isEquivalent, makeSource: makeSource)
        XCTAssertEqual(failures, [])

        // Each occurrence has its own key, so even byte equality finds no duplicate.
        let byBytes = try ProviderConformance.checkSource(
            provider: ClaudeProvider.name, workDirectory: tmpDir, makeSource: makeSource)
        XCTAssertEqual(byBytes, [])
    }

    /// N1: a line that is not a JSON object is archived, then quarantined as
    /// `unparseable` once its attempts run out. That reason is final, so a caller
    /// waiting for captures to be stored does not count it; a retryable reason does.
    func testAnUnparseableLineIsArchivedAndItsQuarantineIsFinal() throws {
        let url = try transcript(Self.sessionID, lines: [Self.userLine(1), "not json at all"], mtime: base)
        XCTAssertEqual(try ClaudeTranscriptSource(projectsDirectory: projectsDir).poll(file: url, into: spool), 2)
        let (drainer, archive) = try makeDrainer()
        var rounds = 0
        while try spool.pendingCount() > 0, rounds < 20 {
            _ = drainer.drainUntilEmpty()
            rounds += 1
        }
        XCTAssertEqual(try spool.pendingCount(), 0)
        XCTAssertEqual(try archive.count(), 2, "the unparseable line's bytes are in the archive")
        let quarantined = try spool.quarantined(limit: 10)
        XCTAssertEqual(quarantined.count, 1)
        let reason = try XCTUnwrap(quarantined.first).reason
        XCTAssertTrue(reason.hasPrefix(ClaudeNormalizerError.unparseableReasonPrefix), reason)
        XCTAssertEqual(ClaudeNormalizerError.unparseableReasonPrefix, "unparseable(\"")
        let permanent = ClaudeNormalizerError.permanentReasonPrefixes
        XCTAssertEqual(try spool.quarantinedCount(excludingReasonPrefixes: permanent), 0)

        // A retryable reason still counts.
        try spool.append([RawRecord(provider: ClaudeProvider.name, sourceKind: ClaudeProvider.hookKind,
                                    dedupKey: "retryable", receivedAt: base, payload: Data("{}".utf8))])
        let id = try XCTUnwrap(try spool.pendingBatch(limit: 1).first?.id)
        try spool.quarantine(id: id, reason: "store write failed: disk I/O error")
        XCTAssertEqual(try spool.quarantinedCount(), 2)
        XCTAssertEqual(try spool.quarantinedCount(excludingReasonPrefixes: permanent), 1)
        XCTAssertEqual(try spool.quarantinedCount(excludingReasonPrefixes: []), 2)
    }

    /// A-7: a byte-identical line that repeats in a file is archived once per
    /// occurrence, at its own offset, and re-delivering those offsets (a replay of
    /// the same records, or a re-read from byte 0) adds nothing.
    func testARepeatedLineIsArchivedOncePerOffsetAndReplayAddsNothing() throws {
        let repeated = Self.userLine(1)
        let lines = [repeated, Self.userLine(2), repeated]
        let url = try transcript(Self.sessionID, lines: lines, mtime: base)
        let source = ClaudeTranscriptSource(projectsDirectory: projectsDir)
        XCTAssertEqual(try source.poll(into: spool), 3)
        let records = try pending()
        let (drainer, archive) = try makeDrainer()
        XCTAssertFalse(drainer.drainUntilEmpty().failed)
        XCTAssertEqual(try archive.count(), 3, "both occurrences of the repeated line are archived")

        let stride = Int64(repeated.utf8.count + 1)
        let firstKey = ClaudeTranscriptPayload.dedupKey(line: repeated, file: url.path, byteOffset: 0)
        let thirdKey = ClaudeTranscriptPayload.dedupKey(
            line: repeated, file: url.path, byteOffset: stride + Int64(lines[1].utf8.count + 1))
        XCTAssertEqual([records[0].dedupKey, records[2].dedupKey], [firstKey, thirdKey])
        XCTAssertNotEqual(firstKey, thirdKey)
        for key in [firstKey, thirdKey] {
            let id = try XCTUnwrap(try archive.id(forDedupKey: key))
            let payload = try ClaudeTranscriptPayload.decode(try XCTUnwrap(try archive.record(id: id)).record.payload)
            XCTAssertEqual(payload.line, repeated)
        }

        // Replay: the same records delivered again are duplicates.
        try spool.append(records)
        let replay = drainer.drainUntilEmpty()
        XCTAssertFalse(replay.failed, replay.failureReason ?? "")
        XCTAssertEqual(replay.conflictCopies, 0)
        XCTAssertEqual(try archive.count(), 3, "a replay adds nothing")

        // A re-read from byte 0 (the cursor is gone) delivers the same offsets.
        try spool.setSourceState(ClaudeTranscriptSource.cursorKey(for: url), Data("garbage".utf8))
        XCTAssertEqual(try source.poll(file: url, into: spool), 3)
        XCTAssertFalse(drainer.drainUntilEmpty().failed)
        XCTAssertEqual(try archive.count(), 3, "a re-read adds nothing")
        XCTAssertEqual(try spool.quarantined(limit: 10).count, 0)
    }

    /// Blank lines after the last record move the cursor with no records; a line
    /// that is not valid UTF-8 is archived like any other (lossy text plus its
    /// exact bytes), so the next wake neither re-scans nor loses it.
    func testTrailingBlankLinesStepTheCursorAndAnUndecodableLineIsArchived() throws {
        let lines = [Self.userLine(1), Self.userLine(2)]
        let url = try transcript(Self.sessionID, lines: lines, mtime: base)
        let junk = Data([0xFF, 0xFE, 0xC3, 0x28])
        let handle = try FileHandle(forWritingTo: url)
        try handle.seekToEnd()
        try handle.write(contentsOf: Data("\n\n".utf8) + junk + Data([0x0A]) + Data("\n".utf8))
        try handle.close()
        try setMTime(url, base.addingTimeInterval(1))
        let size = try XCTUnwrap(
            (try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber)?.intValue)

        let source = ClaudeTranscriptSource(projectsDirectory: projectsDir, linesPerChunk: 1)
        XCTAssertEqual(try source.poll(into: spool), 3)
        let cursor = try XCTUnwrap(try spool.sourceState(ClaudeTranscriptSource.cursorKey(for: url)))
        let object = try XCTUnwrap(try JSONSerialization.jsonObject(with: cursor) as? [String: Any])
        XCTAssertEqual(object["byte_offset"] as? Int, size, "the cursor steps over the trailing blank line")
        XCTAssertEqual(object["line_no"] as? Int, 3)
        XCTAssertEqual(try source.poll(file: url, into: spool), 0)
        let archived = try payloads()
        XCTAssertEqual(archived.prefix(2).map(\.line), lines)
        XCTAssertEqual(archived.prefix(2).map(\.lineBytes), [nil, nil])
        XCTAssertEqual(archived[2].lineBytes, junk, "the exact bytes are kept")
        // swiftlint:disable:next optional_data_string_conversion
        XCTAssertEqual(archived[2].line, String(decoding: junk, as: UTF8.self), "lossy text beside the bytes")

        // A record after the junk continues the numbering from the cursor.
        try appendText(Self.userLine(3) + "\n", to: url, mtime: base.addingTimeInterval(2))
        XCTAssertEqual(try source.poll(file: url, into: spool), 1)
        XCTAssertEqual(try payloads().map(\.lineNo), [1, 2, 3, 4])
    }

    /// A line holding a truncated multi-byte sequence reaches the raw archive with
    /// every byte intact, under a key that hashes those bytes, and a second line
    /// differing only in its bad bytes is its own row.
    func testANonUTF8TranscriptLineReachesTheArchiveByteForByte() throws {
        let valid = Self.userLine(1)
        // A line cut short by a lone multi-byte lead byte, then the same with 0xFF.
        let broken = Data(Self.userLine(2).utf8.prefix(60)) + Data([0xC3]) + Data(#""}}"#.utf8)
        let other = Data(Self.userLine(2).utf8.prefix(60)) + Data([0xFF]) + Data(#""}}"#.utf8)
        XCTAssertNil(String(data: broken, encoding: .utf8))
        let dir = projectsDir.appendingPathComponent("-Users-dev-work-myapp")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("\(Self.sessionID).jsonl")
        try (Data((valid + "\n").utf8) + broken + Data([0x0A]) + other + Data([0x0A])).write(to: url)

        XCTAssertEqual(try ClaudeTranscriptSource(projectsDirectory: projectsDir).poll(into: spool), 3)
        let records = try pending()
        let (drainer, archive) = try makeDrainer()
        _ = drainer.drainUntilEmpty()
        XCTAssertEqual(try archive.count(), 3, "no line is skipped and the two bad lines do not collapse")

        for (record, bytes) in zip(records.suffix(2), [broken, other]) {
            let id = try XCTUnwrap(try archive.id(forDedupKey: record.dedupKey))
            let stored = try XCTUnwrap(try archive.record(id: id))
            let payload = try ClaudeTranscriptPayload.decode(stored.record.payload)
            XCTAssertEqual(payload.lineBytes, bytes)
            XCTAssertEqual(record.dedupKey, ClaudeTranscriptPayload.dedupKey(
                line: payload.line, file: payload.file, byteOffset: try XCTUnwrap(payload.byteOffset),
                lineBytes: bytes))
        }
        // A valid line's payload carries no `line_base64`, so its archived bytes
        // are the same as before this field existed.
        let first = try XCTUnwrap(records.first)
        XCTAssertFalse((String(bytes: first.payload, encoding: .utf8) ?? "line_base64").contains("line_base64"))
    }

    /// Each chunk's offset ends just past its own last line — never past a skipped
    /// line that follows it — so a crash between chunks re-reads only unarchived bytes.
    func testChunkOffsetsEndAtEachChunksLastLineAcrossSkippedLines() throws {
        let first = Self.userLine(1), second = Self.userLine(2), third = Self.userLine(3)
        let url = try transcript("chunks", lines: [first, "", second, "", third])
        var chunks: [(lines: [String], through: Int64)] = []
        let result = try JSONLScanner.streamCompleteLineChunks(at: url, linesPerChunk: 2, bufferSize: 64) {
            chunks.append(($0, $1))
        }
        let len = { (line: String) in Int64(line.utf8.count + 1) }
        XCTAssertEqual(chunks.map(\.lines), [[first, second], [third]])
        XCTAssertEqual(chunks.map(\.through),
                       [len(first) + 1 + len(second), len(first) + 1 + len(second) + 1 + len(third)])
        XCTAssertEqual(result.bytesConsumed, chunks.last?.through)

        // Resuming from the first chunk's offset yields exactly the rest.
        var resumed: [[String]] = []
        _ = try JSONLScanner.streamCompleteLineChunks(
            at: url, startingAtByte: chunks[0].through, linesPerChunk: 2) { lines, _ in resumed.append(lines) }
        XCTAssertEqual(resumed, [[third]])
    }
}

private extension URL {
    var resolvingCanonicalPath: String? { (try? resourceValues(forKeys: [.canonicalPathKey]))?.canonicalPath }
}
