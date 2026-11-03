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
    /// The line, verbatim, without its newline.
    public let line: String

    public init(file: String, lineNo: Int, subagentFile: Bool, line: String) {
        self.file = file
        self.lineNo = lineNo
        self.subagentFile = subagentFile
        self.line = line
    }

    private enum CodingKeys: String, CodingKey {
        case file
        case lineNo = "line_no"
        case subagentFile = "subagent_file"
        case line
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
    /// `(session_id, line_hash)` dedup.
    public static func dedupKey(line: String, file: String) -> String {
        let sessionID = JSONLScanner.parseRawLine(line, lineNo: 0, fileStem: fileStem(file)).sessionId
        return "\(sessionID):\(SHA256.hash(data: Data(line.utf8)).hexString)"
    }

    /// The file name without its `.jsonl` extension, as `JSONLScanner.scanRawLines` derives it.
    public static func fileStem(_ file: String) -> String {
        URL(fileURLWithPath: file).deletingPathExtension().lastPathComponent
    }
}
#endif
