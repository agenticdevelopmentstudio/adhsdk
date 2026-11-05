import Foundation

/// Joins the parts of a display path with `›`.
///
/// A window builds the path from things it knows separately — a project name, a
/// tab title, a pane's name, what that pane says is selected — and any of them
/// can be missing. Dropping the missing ones is the whole job, and it is the
/// part that is easy to get subtly wrong (a dangling separator after a pane
/// with no selection), so it is one function with one test rather than a
/// `joined(separator:)` at each call site (`dry`).
///
/// This is a **display path, not an address**. It is punctuation over strings a
/// human reads; nothing resolves it back to anything.
public enum PaneDisplayPath {

    /// Spaces included: the separator is what goes *between* two segments, and
    /// the alternative is every caller remembering to pad it.
    public static let separator = " › "

    /// The segments that have something to say, joined. A `nil`, an empty
    /// string and a string of spaces are all "nothing".
    public static func format(_ segments: [String?]) -> String {
        segments
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: separator)
    }
}
