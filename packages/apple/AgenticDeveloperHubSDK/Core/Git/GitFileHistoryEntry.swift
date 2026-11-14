import Foundation

/// One commit in a file's history, with the file's path at that commit: a history that
/// follows renames lists commits from before a rename under the name the file had then.
public struct GitFileHistoryEntry: Sendable, Hashable, Identifiable {
    public let commit: GitCommit
    /// The file's path in this commit.
    public let path: String
    /// The path this commit renamed or copied the file from; nil otherwise.
    public let oldPath: String?

    public init(commit: GitCommit, path: String, oldPath: String?) {
        self.commit = commit
        self.path = path
        self.oldPath = oldPath
    }

    public var id: String { commit.id }

    /// The paths a diff of this commit must name to show the change: both sides of a
    /// rename, so git can pair them, else the one path.
    public var paths: [String] { oldPath.map { [$0, path] } ?? [path] }

    /// Parses `git log --format=GitCommit.logFormat --name-status --follow -- <path>`
    /// output, newest first, dropping any record it cannot read.
    ///
    /// Git writes each commit's status lines after its record terminator, so they lead the
    /// next piece: the text before the line where a record's first unit separator falls.
    /// The path is carried from newest to oldest, starting at `path`: a rename or copy
    /// (`R`/`C` with two paths) names both and hands its old path to older commits; any
    /// other status names the path; a commit with none (a merge) keeps the path it had.
    static func parse(log output: String, path: String) -> [GitFileHistoryEntry] {
        var records: [(commit: GitCommit, status: [Substring])] = []
        for piece in output.split(separator: "\u{1E}", omittingEmptySubsequences: true) {
            let recordStart: Substring.Index
            if let unit = piece.firstIndex(of: "\u{1F}") {
                recordStart = piece[..<unit].lastIndex(of: "\n").map { piece.index(after: $0) } ?? piece.startIndex
            } else {
                recordStart = piece.endIndex
            }
            let status = piece[..<recordStart].split(separator: "\n").filter { $0.contains("\t") }
            if !records.isEmpty, !status.isEmpty { records[records.count - 1].status = status }
            let record = piece[recordStart...]
            if !record.isEmpty, let commit = GitCommit.parse(record: record) {
                records.append((commit, []))
            }
        }
        var current = path
        return records.map { record in
            guard let line = record.status.first else {
                return GitFileHistoryEntry(commit: record.commit, path: current, oldPath: nil)
            }
            let fields = line.split(separator: "\t", omittingEmptySubsequences: false)
                .map { GitPathUnquoting.unquote(String($0)) }
            if fields.count == 3, let code = fields[0].first, code == "R" || code == "C" {
                current = fields[1]
                return GitFileHistoryEntry(commit: record.commit, path: fields[2], oldPath: fields[1])
            }
            current = fields.last ?? current
            return GitFileHistoryEntry(commit: record.commit, path: current, oldPath: nil)
        }
    }
}
