import Foundation

/// A branch, remote branch or tag as `git for-each-ref --format=GitRef.forEachRefFormat` reports it.
///
/// `GitBranch` stays as it is for the local-branch picker; this covers every kind a
/// history browser lists.
public struct GitRef: Sendable, Hashable, Identifiable {
    public enum Kind: Sendable, Hashable {
        case localBranch, remoteBranch, tag
    }

    public let kind: Kind
    /// `refs/heads/main`, `refs/remotes/origin/main`, `refs/tags/v1`.
    public let fullName: String
    /// The full name without its kind's prefix: `main`, `origin/main`, `v1`.
    public let name: String
    /// The commit sha: the peeled commit for an annotated tag, the ref's own object otherwise.
    public let target: String
    public let upstream: String?
    public let ahead: Int
    public let behind: Int
    /// Whether this is the checked-out branch.
    public let isHead: Bool

    public init(
        kind: Kind, fullName: String, name: String, target: String,
        upstream: String?, ahead: Int, behind: Int, isHead: Bool
    ) {
        self.kind = kind
        self.fullName = fullName
        self.name = name
        self.target = target
        self.upstream = upstream
        self.ahead = ahead
        self.behind = behind
        self.isHead = isHead
    }

    public var id: String { fullName }

    /// The remote a remote branch belongs to (`origin` for `refs/remotes/origin/x`); nil for every other kind.
    public var remote: String? {
        guard kind == .remoteBranch else { return nil }
        return name.split(separator: "/", maxSplits: 1).first.map(String.init)
    }

    /// Seven fields separated by the unit separator (0x1F), one ref per line.
    public static let forEachRefFormat = "%(refname)%1f%(refname:short)%1f%(objectname)%1f%(*objectname)%1f"
        + "%(upstream:short)%1f%(upstream:track,nobracket)%1f%(HEAD)"

    private static let fieldCount = 7
    private static let prefixes: [(prefix: String, kind: Kind)] = [
        ("refs/heads/", .localBranch), ("refs/remotes/", .remoteBranch), ("refs/tags/", .tag)
    ]

    /// Parses `forEachRefFormat` lines. Drops refs of any other kind (`refs/stash`, notes) and
    /// a remote's `HEAD` symbolic ref.
    ///
    /// The name is the full name less its prefix rather than `%(refname:short)`, which prints
    /// `heads/<name>` for a branch that shares its name with a tag.
    public static func parse(forEachRef output: String) -> [GitRef] {
        output.split(separator: "\n", omittingEmptySubsequences: true).compactMap { line in
            let fields = line.split(separator: "\u{1F}", omittingEmptySubsequences: false).map(String.init)
            guard fields.count == fieldCount else { return nil }
            let fullName = fields[0]
            guard let match = prefixes.first(where: { fullName.hasPrefix($0.prefix) }) else { return nil }
            let name = String(fullName.dropFirst(match.prefix.count))
            guard !name.isEmpty else { return nil }
            if match.kind == .remoteBranch, name.hasSuffix("/HEAD") { return nil }
            let (ahead, behind) = tracking(fields[5])
            return GitRef(
                kind: match.kind,
                fullName: fullName,
                name: name,
                target: fields[3].isEmpty ? fields[2] : fields[3],
                upstream: fields[4].isEmpty ? nil : fields[4],
                ahead: ahead,
                behind: behind,
                isHead: fields[6] == "*"
            )
        }
    }

    /// Reads `ahead N, behind M`, either half alone, `gone` or empty; missing counts are 0.
    private static func tracking(_ track: String) -> (ahead: Int, behind: Int) {
        var ahead = 0
        var behind = 0
        for part in track.split(separator: ",") {
            let words = part.split(separator: " ")
            guard words.count == 2, let count = Int(words[1]) else { continue }
            switch words[0] {
            case "ahead": ahead = count
            case "behind": behind = count
            default: break
            }
        }
        return (ahead, behind)
    }
}
