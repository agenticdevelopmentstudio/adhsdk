import Foundation

/// An agent session a daemon recorded, as the Git window shows it beside the commits
/// and branches it worked on (recipe `workspace/git/git-views`, "Agent sessions").
/// Read-only: the Git window never writes to a daemon.
public struct GitAgentSession: Sendable, Hashable, Identifiable {
    /// The daemon's session id.
    public let id: String
    /// The session's name; nil when it has none.
    public let title: String?
    /// The directory the session ran in.
    public let cwd: String
    /// The branch checked out where it ran; nil when unknown.
    public let branch: String?
    public let startedAt: Date
    public let lastActivityAt: Date

    public init(id: String, title: String?, cwd: String, branch: String?, startedAt: Date, lastActivityAt: Date) {
        self.id = id
        self.title = title
        self.cwd = cwd
        self.branch = branch
        self.startedAt = startedAt
        self.lastActivityAt = lastActivityAt
    }

    /// The title, or the first eight characters of the id when there is none.
    public var displayTitle: String {
        if let title, !title.isEmpty { return title }
        return String(id.prefix(8))
    }
}

/// Where the Git window reads agent sessions from. Nil in its place (ADTerminal, tests,
/// no daemon) means the Git window shows no sessions at all.
public protocol GitSessionsProviding: Sendable {
    /// The sessions whose directory is under one of `roots` and that were active since
    /// `since`. Never throws: any failure answers [].
    func sessions(under roots: [String], since: Date) async -> [GitAgentSession]
}

/// Which sessions belong beside a commit or a branch. Pure.
public enum GitAgentSessionMatcher {

    /// The sessions under `roots` that worked on a commit made at `date` on `branch`
    /// (nil: unknown): those on the same branch, and those active within `slack` of
    /// `date` (`startedAt - slack ≤ date ≤ lastActivityAt + slack`). Newest start first.
    public static func sessions(_ all: [GitAgentSession], forCommitAt date: Date, branch: String?, roots: [String],
                                slack: TimeInterval = 600) -> [GitAgentSession] {
        let rootComponents = components(of: roots)
        let branch = branch.flatMap { $0.isEmpty ? nil : $0 }
        return newestFirst(all.filter { session in
            guard isUnder(session.cwd, rootComponents) else { return false }
            if let branch, session.branch == branch { return true }
            return session.startedAt.addingTimeInterval(-slack) <= date
                && date <= session.lastActivityAt.addingTimeInterval(slack)
        })
    }

    /// The sessions under `roots` that ran on `branch`. Newest start first.
    public static func sessions(_ all: [GitAgentSession], onBranch branch: String,
                                roots: [String]) -> [GitAgentSession] {
        let rootComponents = components(of: roots)
        return newestFirst(all.filter { $0.branch == branch && isUnder($0.cwd, rootComponents) })
    }

    /// Whether `path` is one of `roots` or lies under one, compared by path component, so
    /// `/a/b` is under `/a` but not under `/a/bc`.
    static func isUnder(_ path: String, _ roots: [[String]]) -> Bool {
        let parts = pathParts(path)
        return roots.contains { root in
            !root.isEmpty && parts.count >= root.count && Array(parts.prefix(root.count)) == root
        }
    }

    private static func components(of roots: [String]) -> [[String]] {
        roots.map { pathParts($0) }
    }

    private static func pathParts(_ path: String) -> [String] {
        guard !path.isEmpty else { return [] }
        return URL(fileURLWithPath: path).standardizedFileURL.pathComponents
    }

    private static func newestFirst(_ sessions: [GitAgentSession]) -> [GitAgentSession] {
        sessions.sorted { lhs, rhs in
            lhs.startedAt != rhs.startedAt ? lhs.startedAt > rhs.startedAt : lhs.id < rhs.id
        }
    }
}
