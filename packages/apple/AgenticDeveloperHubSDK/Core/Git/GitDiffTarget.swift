import Foundation

/// What a `GitClient.diff` compares. Paths are relative to the working tree's top level,
/// whichever directory the diff is asked from; an empty path list means every path.
public enum GitDiffTarget: Sendable, Hashable {
    /// The index against the working tree.
    case unstaged(paths: [String])
    /// HEAD against the index; on an unborn HEAD every staged file is added.
    case staged(paths: [String])
    /// An untracked file shown as wholly added (`/dev/null` against the file).
    case untracked(path: String)
    /// A commit against its first parent; a root commit against the empty tree. A merge
    /// and a stash are commits too, so both diff against their first parent.
    case commit(String, paths: [String])
    /// One revision against another.
    case range(from: String, to: String, paths: [String]) // swiftlint:disable:this identifier_name
}

/// How a `GitClient.diff` is rendered.
public struct GitDiffOptions: Sendable, Hashable {
    /// Ignore whitespace when comparing lines (`-w`).
    public var ignoreWhitespace = false
    /// Unchanged lines of context around each change (`-U<n>`).
    public var contextLines = 3

    public init() {}
}
