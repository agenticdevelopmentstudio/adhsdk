#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import CryptoKit
import Foundation

/// The payload of one archived Claude transcript line (Design Ruling 3): the
/// raw line text plus everything a pure normalizer needs to know about where it
/// came from, so normalizing never touches the file system.
///
/// Encoded as a JSON object with sorted keys —
/// `{"file": …, "line": …, "line_no": …, "subagent_file": …}` — so the same line
/// read from the same place always archives as the same bytes.
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

    public init(file: String, lineNo: Int, subagentFile: Bool, line: String, lineBytes: Data? = nil) {
        self.file = file
        self.lineNo = lineNo
        self.subagentFile = subagentFile
        self.line = line
        self.lineBytes = lineBytes
    }

    private enum CodingKeys: String, CodingKey {
        case file
        case lineNo = "line_no"
        case subagentFile = "subagent_file"
        case line
        case lineBytes = "line_base64"
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

    /// The record's dedup key (Design Ruling 3): `"<sessionId>:<sha256 hex of the
    /// line's UTF-8 bytes>"`. The session id is the line's own `sessionId`, else the
    /// file stem — the same attribution and hash as `transcript_lines`'
    /// `(session_id, line_hash)` dedup. A line that is not valid UTF-8 passes its
    /// exact bytes as `lineBytes`, and those are hashed instead of the lossy text,
    /// so two lines differing only in their bad bytes never collapse into one.
    public static func dedupKey(line: String, file: String, lineBytes: Data? = nil) -> String {
        let sessionID = JSONLScanner.parseRawLine(line, lineNo: 0, fileStem: fileStem(file)).sessionId
        return "\(sessionID):\(SHA256.hash(data: lineBytes ?? Data(line.utf8)).hexString)"
    }

    /// The file name without its `.jsonl` extension, as `JSONLScanner.scanRawLines` derives it.
    public static func fileStem(_ file: String) -> String {
        URL(fileURLWithPath: file).deletingPathExtension().lastPathComponent
    }
}
#endif
