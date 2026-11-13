import Foundation

/// The one decoding ladder for captured git output: UTF-8, then ISO Latin-1, never nil.
///
/// The ladder runs per segment, not per capture. The capture is cut at the ASCII separators
/// git's formats use between fields and records — NUL, newline, record separator (0x1E) and
/// unit separator (0x1F) — and each segment falls back to Latin-1 on its own, so one commit
/// with a stray non-UTF-8 byte cannot turn every name and subject on a log page into
/// mojibake. Cutting there is safe: no byte of a UTF-8 multi-byte sequence is below 0x80.
///
/// `String(bytes:encoding:)` rather than `String(decoding:as:)`, as
/// `SubprocessChannel.standardErrorText()` does: `String(decoding:)` would replace the
/// offending bytes with U+FFFD and hand a parser a path that matches nothing on disk.
enum GitOutputDecoding {
    private static let separators: Set<UInt8> = [0x00, 0x0A, 0x1E, 0x1F]

    static func string(_ data: Data) -> String {
        // A capture that is UTF-8 as a whole decodes the same segment by segment.
        if let whole = String(bytes: data, encoding: .utf8) { return whole }
        var result = ""
        var segmentStart = data.startIndex
        for index in data.indices where separators.contains(data[index]) {
            result += segment(data[segmentStart..<index])
            result.unicodeScalars.append(Unicode.Scalar(data[index]))
            segmentStart = data.index(after: index)
        }
        result += segment(data[segmentStart..<data.endIndex])
        return result
    }

    private static func segment(_ bytes: Data) -> String {
        String(bytes: bytes, encoding: .utf8)
            ?? String(bytes: bytes, encoding: .isoLatin1)
            ?? ""
    }
}
