import Foundation

/// One `@@ -o,c +n,c @@ section` block of a file's patch.
public struct GitDiffHunk: Sendable, Hashable {
    public let oldStart: Int
    public let oldCount: Int
    public let newStart: Int
    public let newCount: Int
    /// The text after the second `@@`, trimmed (often the enclosing function).
    public let section: String
    public let lines: [GitDiffLine]

    public init(oldStart: Int, oldCount: Int, newStart: Int, newCount: Int, section: String, lines: [GitDiffLine]) {
        self.oldStart = oldStart
        self.oldCount = oldCount
        self.newStart = newStart
        self.newCount = newCount
        self.section = section
        self.lines = lines
    }
}
