import Foundation

/// One line of a hunk, without its one-character prefix.
public struct GitDiffLine: Sendable, Hashable {
    public enum Kind: Sendable, Hashable {
        case context
        case added
        case removed
        /// `\ No newline at end of file`, which applies to the line before it.
        case noNewlineAtEnd
    }

    public let kind: Kind
    /// The line exactly as git wrote it, so a CRLF file's lines keep their `\r` and a
    /// patch built from them applies.
    public let text: String
    /// `text` without the `\r` of a CRLF line ending, for showing and comparing.
    public var displayText: String {
        text.unicodeScalars.last == "\r" ? String(text.unicodeScalars.dropLast()) : text
    }
    /// The line's number in the old file; `nil` for added lines and markers.
    public let oldNumber: Int?
    /// The line's number in the new file; `nil` for removed lines and markers.
    public let newNumber: Int?

    public init(kind: Kind, text: String, oldNumber: Int?, newNumber: Int?) {
        self.kind = kind
        self.text = text
        self.oldNumber = oldNumber
        self.newNumber = newNumber
    }
}
