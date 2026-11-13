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
    public let text: String
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
