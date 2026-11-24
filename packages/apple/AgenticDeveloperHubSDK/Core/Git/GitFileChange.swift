import Foundation

/// One changed path in one column of the working copy — a row in a staged or
/// unstaged list.
public struct GitFileChange: Sendable, Hashable, Identifiable {
    public let path: String
    public let status: GitFileStatus

    public var id: String { path }
    public var isUntracked: Bool { status == .untracked }

    public init(path: String, status: GitFileStatus) {
        self.path = path
        self.status = status
    }

    /// A status column (`GitStatus.stagedFiles` or `unstagedFiles`) as a list
    /// ordered by path.
    public static func list(_ column: [String: GitFileStatus]) -> [GitFileChange] {
        column.map { GitFileChange(path: $0.key, status: $0.value) }.sorted { $0.path < $1.path }
    }
}
