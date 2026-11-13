import Foundation

/// The one decoding ladder for captured git output: UTF-8, then ISO Latin-1, never nil.
///
/// `String(bytes:encoding:)` rather than `String(decoding:as:)`, to decode a capture
/// the same way `SubprocessChannel.standardErrorText()` does; one framework, one
/// ladder. Neither ladder round-trips a capture git could not express in UTF-8:
/// `String(decoding:)` would replace the offending bytes with U+FFFD and hand a
/// parser a path that matches nothing on disk, while a single invalid byte here
/// re-reads the *whole* capture as Latin-1 and mojibakes every legitimate
/// multi-byte character in it.
enum GitOutputDecoding {
    static func string(_ data: Data) -> String {
        String(bytes: data, encoding: .utf8)
            ?? String(bytes: data, encoding: .isoLatin1)
            ?? ""
    }
}
