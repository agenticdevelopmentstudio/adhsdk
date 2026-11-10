#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation

public enum ClaudeTranscriptSourceError: Error, Equatable {
    /// The file's size or inode could not be read, so its cursor cannot be checked.
    case unreadableAttributes(String)
}

/// Spools Claude Code transcript lines (`~/.claude/projects/**/*.jsonl`) from a
/// per-file byte cursor, the way `JSONLImporter` reads them today.
///
/// - **Records** (Design Ruling 3): one per complete, non-empty line; sourceKind
///   `"transcript"`, payload `ClaudeTranscriptPayload` (canonical path, 1-based
///   line number among non-empty lines, the line's byte offset, subagent flag, the
///   line), dedupKey `ClaudeTranscriptPayload.dedupKey` (session, file stem, offset
///   and line hash, so each occurrence of a repeated line is its own record),
///   receivedAt the file's mtime when read.
/// - **Cursor**: source state `"file:<canonical path>"` holds
///   `{byte_offset, line_no, file_size, inode, head_hash}`. It is resumed only when
///   the inode matches, the file is no shorter than `byte_offset`, and
///   `JSONLScanner.resumeFingerprint` over `[0, byte_offset)` still equals
///   `head_hash`; otherwise the file is read again from byte 0. The archive's dedup
///   keys drop every line still at the offset it was read from; a line the change
///   moved to a new offset is archived again there. Each chunk of at most
///   `linesPerChunk` records is appended together with the cursor just past its
///   last line, in one transaction.
/// - **Torn lines**: a trailing line Claude is still writing is neither spooled nor
///   covered by the cursor (`JSONLScanner.streamCompleteLines`).
/// - **Watermark**: source state `"watermark"` is the newest mtime of the files a
///   sweep fully consumed (`jsonl_import_last_run_at` today). A sweep takes files
///   with a newer mtime, oldest first, `filesPerPoll` at a time plus every file
///   sharing the boundary mtime; a file that failed stops the watermark short of
///   its mtime, so it and everything newer is visited again next time.
///
/// Paths are canonicalized (`/private/var/…`, not `/var/…`) so a tail woken with a
/// hook's spelling of a path and the sweep's walk share one cursor and one payload.
public final class ClaudeTranscriptSource: IngestSource {
    public static let watermarkKey = "watermark"

    public let provider = ClaudeProvider.name
    public let projectsDirectory: URL
    public let filesPerPoll: Int
    public let linesPerChunk: Int
    private let faultInjector: (@Sendable (SourceStep) throws -> Void)?

    /// `faultInjector` is for tests: it fires around each chunk's append (see `SourceStep`).
    public init(projectsDirectory: URL, filesPerPoll: Int = 50, linesPerChunk: Int = 500,
                faultInjector: (@Sendable (SourceStep) throws -> Void)? = nil) {
        self.projectsDirectory = projectsDirectory
        self.filesPerPoll = max(1, filesPerPoll)
        self.linesPerChunk = max(1, linesPerChunk)
        self.faultInjector = faultInjector
    }

    /// The source-state key holding `file`'s cursor.
    public static func cursorKey(for file: URL) -> String {
        "file:\(canonicalPath(file))"
    }

    // MARK: - Polling

    /// One sweep. Files newer than the watermark are read a batch at a time; a batch
    /// that yields nothing new (files already read through their cursors) moves on to
    /// the next, so 0 means there is nothing new, not that the batch was stale.
    /// A spool append that throws ends the sweep and is rethrown; any other per-file
    /// failure skips that file and holds the watermark below it.
    public func poll(into spool: ProviderSpool) throws -> Int {
        let watermark = try storedWatermark(spool)
        let eligible = JSONLScanner.discoverFilesWithModificationDates(under: projectsDirectory)
            .filter { entry in watermark.map { entry.modified > $0 } ?? true }
            .sorted { ($0.modified, $0.url.path) < ($1.modified, $1.url.path) }

        var start = 0
        while start < eligible.count {
            var end = min(start + filesPerPoll, eligible.count)
            let boundary = eligible[end - 1].modified
            while end < eligible.count, eligible[end].modified == boundary { end += 1 }
            let batch = eligible[start..<end]
            start = end

            var appended = 0
            var earliestFailure: Date?
            for (url, modified) in batch {
                do {
                    appended += try read(url, into: spool)
                } catch let error as SpoolAppendError {
                    throw error.underlying
                } catch {
                    earliestFailure = earliestFailure.map { min($0, modified) } ?? modified
                }
            }
            // Oldest first, so the newest file before the earliest failure is the
            // furthest the watermark can honestly move.
            let consumed = batch.last { entry in earliestFailure.map { entry.modified < $0 } ?? true }
            if let consumed, watermark.map({ consumed.modified > $0 }) ?? true {
                try spool.setSourceState(Self.watermarkKey, Self.encodeWatermark(consumed.modified))
            }
            if appended > 0 || earliestFailure != nil { return appended }
        }
        return 0
    }

    /// The tailer's per-file wake: reads just `file` from its cursor. Never moves the
    /// watermark, which only a sweep over every file can justify. A file that no
    /// longer exists has nothing new.
    public func poll(file: URL, into spool: ProviderSpool) throws -> Int {
        guard FileManager.default.fileExists(atPath: file.path) else { return 0 }
        do {
            return try read(file, into: spool)
        } catch let error as SpoolAppendError {
            throw error.underlying
        }
    }

    // MARK: - One file

    /// Marks a spool failure, which ends the whole poll, apart from a per-file one.
    private struct SpoolAppendError: Error {
        let underlying: any Error
    }

    private struct Cursor: Codable, Equatable {
        var byteOffset: Int64
        var lineNo: Int
        var fileSize: Int64
        var inode: UInt64
        var headHash: String

        enum CodingKeys: String, CodingKey {
            case byteOffset = "byte_offset"
            case lineNo = "line_no"
            case fileSize = "file_size"
            case inode
            case headHash = "head_hash"
        }
    }

    private func read(_ file: URL, into spool: ProviderSpool) throws -> Int {
        let path = Self.canonicalPath(file)
        let url = URL(fileURLWithPath: path)
        let key = "file:\(path)"
        let identity: (size: Int64, inode: UInt64, modified: Date)? = autoreleasepool {
            guard let attributes = try? FileManager.default.attributesOfItem(atPath: path),
                  let size = (attributes[.size] as? NSNumber)?.int64Value,
                  let inode = (attributes[.systemFileNumber] as? NSNumber)?.uint64Value,
                  let modified = attributes[.modificationDate] as? Date
            else { return nil }
            return (size, inode, modified)
        }
        guard let identity else { throw ClaudeTranscriptSourceError.unreadableAttributes(path) }

        var startOffset: Int64 = 0
        var lineNo = 0
        if let stored = try spool.sourceState(key),
           let cursor = try? JSONDecoder().decode(Cursor.self, from: stored),
           cursor.inode == identity.inode,
           identity.size >= cursor.byteOffset,
           cursor.headHash == (try JSONLScanner.resumeFingerprint(at: url, upTo: cursor.byteOffset)) {
            if identity.size == cursor.byteOffset { return 0 }
            startOffset = cursor.byteOffset
            lineNo = cursor.lineNo
        }

        let subagent = JSONLScanner.isSubagentPath(path)
        var appended = 0
        var committed = startOffset
        func commit(_ records: [RawRecord], through offset: Int64) throws {
            let cursor = Cursor(
                byteOffset: offset, lineNo: lineNo, fileSize: identity.size, inode: identity.inode,
                headHash: try JSONLScanner.resumeFingerprint(at: url, upTo: offset))
            let state = try JSONEncoder().encode(cursor)
            do {
                try faultInjector?(.beforeAppend)
                try spool.append(records, settingSourceState: key, to: state)
                try faultInjector?(.afterAppend)
            } catch {
                throw SpoolAppendError(underlying: error)
            }
            committed = offset
            appended += records.count
        }

        // Every complete line is archived, one that is not valid UTF-8 included
        // (lossy text plus its exact bytes): no captured byte is skipped.
        let streamed = try JSONLScanner.streamCompleteScannedLineChunks(
            at: url, startingAtByte: startOffset, linesPerChunk: linesPerChunk
        ) { lines, through in
            try autoreleasepool {
                var records: [RawRecord] = []
                records.reserveCapacity(lines.count)
                for scanned in lines {
                    lineNo += 1
                    let payload = ClaudeTranscriptPayload(
                        file: path, lineNo: lineNo, subagentFile: subagent, line: scanned.text,
                        lineBytes: scanned.invalidUTF8Bytes, byteOffset: scanned.startOffset)
                    records.append(RawRecord(
                        provider: provider, sourceKind: ClaudeProvider.transcriptKind,
                        dedupKey: ClaudeTranscriptPayload.dedupKey(
                            line: scanned.text, file: path, byteOffset: scanned.startOffset,
                            lineBytes: scanned.invalidUTF8Bytes),
                        receivedAt: identity.modified, payload: try ClaudeTranscriptPayload.encode(payload)))
                }
                try commit(records, through: through)
            }
        }
        // Blank lines after the last record: step the cursor over them too, so they
        // are not re-scanned on every wake.
        if streamed.bytesConsumed > committed {
            try commit([], through: streamed.bytesConsumed)
        }
        return appended
    }

    // MARK: - Helpers

    /// `/private/var/…` rather than `/var/…`: the spelling the directory walk
    /// returns, so every route to one file names it the same way.
    static func canonicalPath(_ file: URL) -> String {
        (try? file.resourceValues(forKeys: [.canonicalPathKey]))?.canonicalPath ?? file.standardizedFileURL.path
    }

    /// Stored as `timeIntervalSinceReferenceDate` — `Date`'s own representation — so
    /// it round-trips exactly and a file at the boundary mtime compares equal.
    private static func encodeWatermark(_ date: Date) -> Data {
        Data(String(date.timeIntervalSinceReferenceDate).utf8)
    }

    private func storedWatermark(_ spool: ProviderSpool) throws -> Date? {
        guard let data = try spool.sourceState(Self.watermarkKey),
              let text = String(data: data, encoding: .utf8),
              let value = Double(text) else { return nil }
        return Date(timeIntervalSinceReferenceDate: value)
    }
}
#endif
