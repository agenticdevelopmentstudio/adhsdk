import Foundation

/// One file's section of a patch: what happened to it and its hunks.
public struct GitFileDiff: Sendable, Hashable, Identifiable {
    public enum Change: Sendable, Hashable {
        case added
        case deleted
        case modified
        case renamed(similarity: Int)
        case copied(similarity: Int)
        /// The object type changed (a file became a symlink, say).
        case typeChanged
    }

    /// `nil` when the old side is `/dev/null` (an added file).
    public let oldPath: String?
    /// `nil` when the new side is `/dev/null` (a deleted file).
    public let newPath: String?
    public let change: Change
    public let isBinary: Bool
    public let hunks: [GitDiffHunk]

    public init(oldPath: String?, newPath: String?, change: Change, isBinary: Bool, hunks: [GitDiffHunk]) {
        self.oldPath = oldPath
        self.newPath = newPath
        self.change = change
        self.isBinary = isBinary
        self.hunks = hunks
    }

    /// The new path, or the old one for a deleted file.
    public var path: String { newPath ?? oldPath ?? "" }

    public var id: String { path }
}
