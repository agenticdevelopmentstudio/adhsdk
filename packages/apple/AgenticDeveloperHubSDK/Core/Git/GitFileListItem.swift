import Foundation

/// One row of the git window's changed-files list (recipe `workspace/git/git-views`,
/// file-list-item): a path, the path it came from for a rename or copy, and its status.
/// Made from a working-copy status entry or from a file of a diff.
public struct GitFileListItem: Sendable, Hashable, Identifiable {
    /// The file's path: the new path, or the old one for a deleted file.
    public let path: String
    /// The path a rename or copy came from; nil for anything else, and for a rename or
    /// copy whose paths are the same.
    public let oldPath: String?
    public let status: GitFileStatus

    public init(path: String, oldPath: String?, status: GitFileStatus) {
        self.path = path
        self.oldPath = oldPath
        self.status = status
    }

    /// A working-copy entry: its path and status, no old path.
    public init(change: GitFileChange) {
        self.init(path: change.path, oldPath: nil, status: change.status)
    }

    /// A file of a diff: its path, the status of its change, and its old path when it is
    /// a rename or copy from a different path.
    public init(diff: GitFileDiff) {
        let status: GitFileStatus
        let keepsOldPath: Bool
        switch diff.change {
        case .added: status = .added; keepsOldPath = false
        case .deleted: status = .deleted; keepsOldPath = false
        case .modified, .typeChanged: status = .modified; keepsOldPath = false
        case .renamed: status = .renamed; keepsOldPath = true
        case .copied: status = .copied; keepsOldPath = true
        }
        let oldPath = keepsOldPath && diff.oldPath != diff.path ? diff.oldPath : nil
        self.init(path: diff.path, oldPath: oldPath, status: status)
    }

    /// `old → new` for a rename or copy, the path otherwise.
    public var title: String {
        guard let oldPath else { return path }
        return "\(oldPath) → \(path)"
    }

    public var id: String { path }
}
