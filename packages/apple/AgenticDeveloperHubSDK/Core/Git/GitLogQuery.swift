import Foundation

/// A history request: which revisions, which path, which filters, which page.
public struct GitLogQuery: Sendable, Hashable {
    /// What to walk; ignored when `followRenames` is set with a `path`.
    public var revisions: [String] = ["--branches", "--tags", "--remotes", "HEAD"]
    public var path: String?
    /// Follow `path` across renames. `git log --follow` takes exactly one path and walks from `HEAD`.
    public var followRenames = false
    public var author: String?
    /// Searched case-insensitively in commit messages.
    public var messageGrep: String?
    /// Commits that change the number of occurrences of this text (`-S`).
    public var pickaxe: String?
    public var limit = 500
    public var skip = 0

    public init() {}

    /// The full argument list after `log`. Never passes `-z`: `GitCommit.logFormat` separates
    /// its own records.
    public func arguments() -> [String] {
        var arguments = [
            "--date-order",
            "--format=" + GitCommit.logFormat,
            "--max-count=\(limit)",
            "--skip=\(skip)"
        ]
        if let author { arguments.append("--author=" + author) }
        if let messageGrep { arguments += ["--grep=" + messageGrep, "--regexp-ignore-case"] }
        if let pickaxe { arguments.append("-S" + pickaxe) }
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
