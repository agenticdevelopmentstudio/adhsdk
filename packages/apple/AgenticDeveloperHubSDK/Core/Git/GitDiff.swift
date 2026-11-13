import Foundation

/// A parsed unified patch, as `git diff`/`git show` print it: one entry per file.
public struct GitDiff: Sendable, Hashable {
    public let files: [GitFileDiff]

    public init(files: [GitFileDiff]) {
        self.files = files
    }

    /// Parses already-decoded patch text. Input it cannot read is skipped, never fatal.
    public static func parse(patch: String) -> GitDiff {
        GitDiff(files: GitPatchParser.parse(patch))
    }
}
