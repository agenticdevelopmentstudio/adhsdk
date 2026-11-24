import Foundation

/// One entry of a ref's reflog, as `git reflog show -z --format=GitReflogEntry.format`
/// reports it (recipe `foundation/git/git-client`, "Reflog"), newest first.
public struct GitReflogEntry: Sendable, Hashable, Identifiable {
    /// `HEAD@{3}`.
    public let selector: String
    /// The commit the ref pointed at after this entry.
    public let sha: String
    /// The commit it pointed at before: the next older entry's sha; nil for the oldest
    /// entry read.
    public let previousSha: String?
    /// The reflog subject before its first `: ` ("commit (amend)", "rebase (finish)",
    /// "checkout", "reset"); the whole subject when it has no `: `.
    public let action: String
    /// The reflog subject after its first `: `; empty when it has none.
    public let message: String
    /// The committer date of `sha`.
    public let date: Date

    public var id: String { selector }

    public init(selector: String, sha: String, previousSha: String?, action: String, message: String, date: Date) {
        self.selector = selector
        self.sha = sha
        self.previousSha = previousSha
        self.action = action
        self.message = message
        self.date = date
    }

    /// The sha's first eight characters, as `GitCommit.shortID` shows a commit.
    public var shortSha: String { String(sha.prefix(8)) }

    /// Selector, sha, reflog subject and committer epoch, separated by the unit
    /// separator (0x1F); with `-z` each record ends in NUL.
    public static let format = "%gd%x1f%H%x1f%gs%x1f%ct"

    /// Parses NUL-separated `format` records, newest first, dropping any it cannot read.
    /// The subject is every field between the sha and the date, so a subject holding a
    /// unit separator survives; each entry's `previousSha` is the next record's sha.
    public static func parse(reflog output: String) -> [GitReflogEntry] {
        let records: [(selector: String, sha: String, subject: String, date: Date)] =
            output.split(separator: "\0", omittingEmptySubsequences: true).compactMap { raw in
                let record = raw.drop { $0 == "\n" }
                let fields = record.split(separator: "\u{1F}", omittingEmptySubsequences: false)
                guard fields.count >= 4, !fields[0].isEmpty, !fields[1].isEmpty,
                      let seconds = Int64(fields[fields.count - 1].trimmingCharacters(in: .whitespacesAndNewlines))
                else { return nil }
                let subject = fields[2..<(fields.count - 1)].joined(separator: "\u{1F}")
                return (String(fields[0]), String(fields[1]), subject,
                        Date(timeIntervalSince1970: TimeInterval(seconds)))
            }
        return records.enumerated().map { index, record in
            let (action, message) = split(subject: record.subject)
            let previous = records.indices.contains(index + 1) ? records[index + 1].sha : nil
            return GitReflogEntry(selector: record.selector, sha: record.sha, previousSha: previous,
                                  action: action, message: message, date: record.date)
        }
    }

    /// `commit (amend): fix: typo` → (`commit (amend)`, `fix: typo`).
    static func split(subject: String) -> (action: String, message: String) {
        guard let separator = subject.range(of: ": ") else { return (subject, "") }
        return (String(subject[..<separator.lowerBound]), String(subject[separator.upperBound...]))
    }
}

/// What the user asked the reflog browser to do with an entry. The view runs none of
/// it; the window's session does.
public enum GitReflogIntent: Equatable {
    /// Move HEAD (its branch, when one is checked out) to the entry's commit.
    case reset(GitReflogEntry, GitResetMode)
    /// Check the entry's commit out on a detached HEAD.
    case checkout(GitReflogEntry)
    /// Ask for a name and create a branch at the entry's commit.
    case createBranch(GitReflogEntry)
}
