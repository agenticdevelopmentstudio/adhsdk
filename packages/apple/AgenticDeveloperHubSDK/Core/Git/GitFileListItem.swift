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

    /// The files of `git diff --name-status -z` output, in order. Each record is a status
    /// token and a path, or for a rename or copy (`R087`, `C100`) a token, the old path and
    /// the new one, all NUL-terminated and never quoted, so any byte a path can hold
    /// survives. A type change counts as modified; a truncated last record is dropped.
    public static func parse(nameStatus output: String) -> [GitFileListItem] {
        var fields = output.split(separator: "\0", omittingEmptySubsequences: false).map(String.init)
        if fields.last == "" { fields.removeLast() }
        var items: [GitFileListItem] = []
        var index = 0
        while index < fields.count, let letter = fields[index].first {
            let pathCount = letter == "R" || letter == "C" ? 2 : 1
            guard index + pathCount < fields.count else { break }
            let status: GitFileStatus
            switch letter {
            case "A": status = .added
            case "D": status = .deleted
            case "R": status = .renamed
            case "C": status = .copied
            case "U": status = .conflicted
            default: status = .modified
            }
            if pathCount == 2 {
                let oldPath = fields[index + 1]
                let path = fields[index + 2]
                items.append(GitFileListItem(path: path, oldPath: oldPath == path ? nil : oldPath, status: status))
            } else {
                items.append(GitFileListItem(path: fields[index + 1], oldPath: nil, status: status))
            }
            index += 1 + pathCount
        }
        return items
    }

    /// `old → new` for a rename or copy, the path otherwise.
    public var title: String {
        guard let oldPath else { return path }
        return "\(oldPath) → \(path)"
    }

    public var id: String { path }
}
