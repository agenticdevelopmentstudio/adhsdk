#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import CryptoKit
import Foundation

/// The payload of one archived Claude transcript line (Design Ruling 3): the
/// raw line text plus everything a pure normalizer needs to know about where it
/// came from, so normalizing never touches the file system.
///
/// Encoded as a JSON object with sorted keys —
/// `{"byte_offset": …, "file": …, "line": …, "line_no": …, "subagent_file": …}` —
/// so the same line read from the same place always archives as the same bytes.
public struct ClaudeTranscriptPayload: Codable, Equatable, Sendable {
    /// The transcript's absolute path.
    public let file: String
    /// 1-based index among the file's non-empty lines (`JSONLScanner.rawLines`).
    public let lineNo: Int
    /// Whether the file is a subagent's own transcript (`JSONLScanner.isSubagentPath`).
    public let subagentFile: Bool
    /// The line, verbatim, without its newline — or, when its bytes are not valid
    /// UTF-8, decoded with U+FFFD in place of each bad sequence (see `lineBytes`).
    public let line: String
    /// The line's exact bytes, kept only when they are not valid UTF-8 and `line`
    /// is therefore lossy, so the archive still holds every captured byte. Encoded
    /// as base64 under `line_base64`; absent (and the payload bytes unchanged) for
    /// every valid line.
    public let lineBytes: Data?
    /// The byte offset in the file where the line starts (`JSONLScanner.ScannedLine.startOffset`),
    /// part of the dedup key. `ClaudeTranscriptSource` always sets it; nil only for a
    /// payload built without a file position.
    public let byteOffset: Int64?

    public init(file: String, lineNo: Int, subagentFile: Bool, line: String, lineBytes: Data? = nil,
                byteOffset: Int64? = nil) {
        self.file = file
        self.lineNo = lineNo
        self.subagentFile = subagentFile
        self.line = line
        self.lineBytes = lineBytes
        self.byteOffset = byteOffset
    }

    private enum CodingKeys: String, CodingKey {
        case file
        case lineNo = "line_no"
        case subagentFile = "subagent_file"
        case line
        case lineBytes = "line_base64"
        case byteOffset = "byte_offset"
    }

    /// The payload bytes: sorted keys, slashes unescaped.
    public static func encode(_ payload: ClaudeTranscriptPayload) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(payload)
    }

    public static func decode(_ data: Data) throws -> ClaudeTranscriptPayload {
        try JSONDecoder().decode(ClaudeTranscriptPayload.self, from: data)
    }

    /// The record's dedup key: one occurrence of a line at one place in one file,
    /// `"<sessionId>:<file stem>@<byteOffset>:<sha256 hex of the line's bytes>"`.
    /// The session id is the line's own `sessionId`, else the file stem. A line
    /// that is not valid UTF-8 passes its exact bytes as `lineBytes`, and those are
    /// hashed instead of the lossy text.
    ///
    /// - The position makes every occurrence its own record: a byte-identical line
    ///   that repeats in a file is archived once per offset.
    /// - The same bytes at the same offset are the same key, so re-delivering a
    ///   line (a replay, a re-read after a cursor reset) dedups.
    /// - The hash keeps a rewritten file apart: different bytes now at an offset
    ///   an earlier line held get a key of their own instead of colliding with it.
    ///   A line a rewrite moved to a new offset is archived again there.
    /// - The stem, not the full path, names the file, so the same transcript seen
    ///   under a renamed project directory keeps its keys.
    public static func dedupKey(line: String, file: String, byteOffset: Int64, lineBytes: Data? = nil) -> String {
        let stem = fileStem(file)
        let sessionID = JSONLScanner.parseRawLine(line, lineNo: 0, fileStem: stem).sessionId
        let hash = SHA256.hash(data: lineBytes ?? Data(line.utf8)).hexString
        return "\(sessionID):\(stem)@\(byteOffset):\(hash)"
    }

    /// The file name without its `.jsonl` extension, as `JSONLScanner.scanRawLines` derives it.
    public static func fileStem(_ file: String) -> String {
        URL(fileURLWithPath: file).deletingPathExtension().lastPathComponent
    }
}
#endif
