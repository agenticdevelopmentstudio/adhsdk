import Foundation

/// One stash entry as `git stash list -z --format=GitStash.listFormat` reports it.
public struct GitStash: Sendable, Hashable {
    /// `N` in `stash@{N}`.
    public let index: Int
    /// The stash commit's sha.
    public let id: String
    public let message: String
    public let date: Date

    public init(index: Int, id: String, message: String, date: Date) {
        self.index = index
        self.id = id
        self.message = message
        self.date = date
    }

    /// Selector, sha, committer epoch and reflog subject, separated by the unit separator (0x1F).
    public static let listFormat = "%gd%x1f%H%x1f%ct%x1f%gs"

    /// Parses NUL-separated `listFormat` records, dropping any it cannot read.
    public static func parse(list output: String) -> [GitStash] {
        output.split(separator: "\0", omittingEmptySubsequences: true).compactMap { raw in
            let record = raw.drop { $0 == "\n" }
            let fields = record.split(separator: "\u{1F}", maxSplits: 3, omittingEmptySubsequences: false)
            guard fields.count == 4,
                  let index = index(fromSelector: fields[0]),
                  !fields[1].isEmpty,
                  let seconds = Int64(fields[2]) else { return nil }
            return GitStash(
                index: index,
                id: String(fields[1]),
                message: String(fields[3]),
                date: Date(timeIntervalSince1970: TimeInterval(seconds))
            )
        }
    }

    /// `stash@{12}` → 12.
    private static func index(fromSelector selector: Substring) -> Int? {
        guard let open = selector.firstIndex(of: "{"), selector.last == "}" else { return nil }
        return Int(selector[selector.index(after: open)..<selector.index(before: selector.endIndex)])
    }
}
