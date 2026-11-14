import Foundation

/// A history request: which revisions, which path, which filters, which page.
public struct GitLogQuery: Sendable, Hashable {
    /// What to walk; ignored when `followRenames` is set with a `path`.
    public var revisions: [String] = ["--branches", "--tags", "--remotes", "HEAD"]
    public var path: String?
    /// Follow `path` across renames. `git log --follow` takes exactly one path and walks from `HEAD`.
    public var followRenames = false
    /// Matched literally (`--fixed-strings`), like `messageGrep`.
    public var author: String?
    /// Searched case-insensitively and literally in commit messages.
    public var messageGrep: String?
    /// Commits that change the number of occurrences of this text (`-S`).
    public var pickaxe: String?
    /// List each commit's changed paths and their status after its record (`--name-status`).
    public var nameStatus = false
    public var limit = 500
    public var skip = 0

    public init() {}

    /// The full argument list after `log`. Never passes `-z`: `GitCommit.logFormat` separates
    /// its own records. `--no-color` and `--no-show-signature` keep a user's `color.ui=always`
    /// or `log.showSignature=true` from writing escape codes or gpg lines into the records.
    public func arguments() -> [String] {
        var arguments = [
            "--no-color",
            "--no-show-signature",
            "--date-order",
            "--format=" + GitCommit.logFormat,
            "--max-count=\(limit)",
            "--skip=\(skip)"
        ]
        if let author { arguments.append("--author=" + author) }
        if let messageGrep { arguments += ["--grep=" + messageGrep, "--regexp-ignore-case"] }
        // What a person types in the search field is text, not a pattern: `(x)` or `a.b`
        // finds itself, and a stray `[` is not an error.
        if author != nil || messageGrep != nil { arguments.append("--fixed-strings") }
        if let pickaxe { arguments.append("-S" + pickaxe) }
        if nameStatus { arguments.append("--name-status") }
        if let path {
            if followRenames {
                arguments += ["--follow", "--", path]
            } else {
                arguments += revisions + ["--", path]
            }
        } else {
            arguments += revisions
        }
        return arguments
    }
}
