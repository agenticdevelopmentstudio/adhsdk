import Foundation

/// One commit as `git log --format=GitCommit.logFormat` reports it.
public struct GitCommit: Sendable, Hashable, Identifiable {
    /// The full sha.
    public let id: String
    /// Every parent, in order: one for an ordinary commit, two or more for a merge, none for a root.
    public let parents: [String]
    public let author: GitPerson
    public let committer: GitPerson
    public let subject: String
    /// The message after the subject, interior newlines kept, trailing newlines removed.
    public let body: String

    public init(
        id: String, parents: [String], author: GitPerson, committer: GitPerson, subject: String, body: String
    ) {
        self.id = id
        self.parents = parents
        self.author = author
        self.committer = committer
        self.subject = subject
        self.body = body
    }

    /// The first eight characters of the sha.
    public var shortID: String { String(id.prefix(8)) }

    /// Ten fields separated by the unit separator (0x1F), each record terminated by the record
    /// separator (0x1E). Without `-z`, git also writes a newline after each record.
    public static let logFormat = "%H%x1f%P%x1f%an%x1f%ae%x1f%at%x1f%cn%x1f%ce%x1f%ct%x1f%s%x1f%b%x1e"

    private static let unitSeparator: Character = "\u{1F}"
    private static let recordSeparator: Character = "\u{1E}"
    /// The fields before subject and body: sha, parents, author name/email/epoch, committer name/email/epoch.
    private static let leadingFieldCount = 8

    /// Parses `logFormat` output, dropping any record it cannot read.
    public static func parse(log output: String) -> [GitCommit] {
        output.split(separator: recordSeparator, omittingEmptySubsequences: true).compactMap { raw in
            // The format is a terminator, so every record after the first starts with git's newline.
            let record = raw.drop { $0 == "\n" }
            guard !record.isEmpty else { return nil }
            return parse(record: record)
        }
    }

    private static func parse(record: Substring) -> GitCommit? {
        // The leading fields come from the front; the rest is subject and body, split at the
        // *last* unit separator so one inside a subject survives (one inside a body cannot).
        var fields = record.split(
            separator: unitSeparator, maxSplits: leadingFieldCount, omittingEmptySubsequences: false
        )
        guard fields.count == leadingFieldCount + 1,
              let lastSeparator = fields[leadingFieldCount].lastIndex(of: unitSeparator) else { return nil }
        let tail = fields.removeLast()
        let subject = String(tail[..<lastSeparator])
        var body = tail[tail.index(after: lastSeparator)...]
        while body.last == "\n" { body = body.dropLast() }

        let sha = String(fields[0])
        guard !sha.isEmpty,
              let author = person(name: fields[2], email: fields[3], epoch: fields[4]),
              let committer = person(name: fields[5], email: fields[6], epoch: fields[7]) else { return nil }
        return GitCommit(
            id: sha,
            parents: fields[1].split(separator: " ").map(String.init),
            author: author,
            committer: committer,
            subject: subject,
            body: String(body)
        )
    }

    private static func person(name: Substring, email: Substring, epoch: Substring) -> GitPerson? {
        guard let seconds = Int64(epoch) else { return nil }
        return GitPerson(
            name: String(name), email: String(email), date: Date(timeIntervalSince1970: TimeInterval(seconds))
        )
    }
}
