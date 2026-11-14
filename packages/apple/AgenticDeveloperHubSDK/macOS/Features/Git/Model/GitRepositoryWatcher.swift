import Foundation
import AgenticDeveloperHubSDKCore

/// What a change on disk means for a repository model: which of its parts to reload.
public enum GitRepositoryChange: Sendable, Hashable, CaseIterable {
    /// Branches, tags, HEAD, worktrees.
    case refs
    /// The commit list.
    case history
    /// The index or a file in the working tree.
    case workingCopy
    /// A merge, rebase or cherry-pick starting or ending.
    case operation
}

/// Reports changes to a repository, already sorted into kinds. The model only ever
/// talks to this, so a test can stand in for FSEvents.
public protocol GitRepositoryWatching: AnyObject {
    func start(onChange: @escaping @Sendable (Set<GitRepositoryChange>) -> Void)
    func stop()
}

/// Watches a working tree, its git directory and the common directory (all three
/// differ for a linked worktree) through the toolkit's `FileSystemWatcher`, classifies
/// each path, and reports the union of a burst once it has been quiet for 300 ms.
///
/// Confined to the main queue: `FileSystemWatcher` delivers there, and `start`/`stop`
/// are called there.
public final class GitRepositoryWatcher: GitRepositoryWatching, @unchecked Sendable {
    static let quietPeriod: TimeInterval = 0.3

    private let root: String
    private let gitDirectory: String
    private let commonDirectory: String
    private var fileWatcher: FileSystemWatcher?
    private var pending: Set<GitRepositoryChange> = []
    private var flush: DispatchWorkItem?
    var onChange: (@Sendable (Set<GitRepositoryChange>) -> Void)?

    public init(root: URL, gitDirectory: URL, commonDirectory: URL) {
        // FSEvents reports canonical paths (`/private/var/...`, `/private/tmp/...`), so the
        // roots are canonicalised with realpath(3) or no reported path would ever match one.
        // Not `resolvingSymlinksInPath()`: it strips a leading `/private`, the opposite.
        self.root = Self.canonicalPath(root)
        self.gitDirectory = Self.canonicalPath(gitDirectory)
        self.commonDirectory = Self.canonicalPath(commonDirectory)
    }

    /// `url`'s path with every symlink resolved the way the kernel spells it, keeping
    /// `/private`; the standardized path when it does not exist.
    static func canonicalPath(_ url: URL) -> String {
        let path = url.standardizedFileURL.path
        guard let resolved = realpath(path, nil) else { return path }
        defer { free(resolved) }
        return String(cString: resolved)
    }

    deinit {
        fileWatcher?.stop()
        flush?.cancel()
    }

    public func start(onChange: @escaping @Sendable (Set<GitRepositoryChange>) -> Void) {
        self.onChange = onChange
        guard fileWatcher == nil else { return }
        let watcher = FileSystemWatcher(rootPaths: [root, gitDirectory, commonDirectory],
                                        excludedPrefixes: [commonDirectory + "/objects"]) { [weak self] paths in
            // FileSystemWatcher hands its paths over on the main queue.
            self?.receive(paths: paths)
        }
        fileWatcher = watcher
        watcher.start()
    }

    public func stop() {
        fileWatcher?.stop()
        fileWatcher = nil
        flush?.cancel()
        flush = nil
        pending = []
        onChange = nil
    }

    /// Classifies `paths` (absolute) and schedules one report of everything gathered
    /// since the last one, after the quiet period. Main queue only.
    func receive(paths: [String]) {
        for path in paths {
            guard let relative = Self.relativePath(of: path, root: root, gitDirectory: gitDirectory,
                                                   commonDirectory: commonDirectory) else { continue }
            pending.formUnion(Self.classify(relativePath: relative))
        }
        guard !pending.isEmpty else { return }
        flush?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            let changes = self.pending
            self.pending = []
            self.flush = nil
            if !changes.isEmpty { self.onChange?(changes) }
        }
        flush = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.quietPeriod, execute: work)
    }

    /// `path` relative to the working tree, with anything in the git directory or the
    /// common directory written as `.git/<path>` whatever the directory is really called;
    /// nil when it is under none of them. The git directory is tried first, since it can
    /// sit inside the working tree (`<root>/.git`) or inside the common directory
    /// (`<common>/worktrees/<name>`).
    static func relativePath(of path: String, root: String, gitDirectory: String,
                             commonDirectory: String) -> String? {
        if let rest = remainder(of: path, under: gitDirectory) {
            return rest.isEmpty ? ".git" : ".git/" + rest
        }
        if let rest = remainder(of: path, under: commonDirectory) {
            return rest.isEmpty ? ".git" : ".git/" + rest
        }
        return remainder(of: path, under: root)
    }

    private static func remainder(of path: String, under directory: String) -> String? {
        if path == directory { return "" }
        guard path.hasPrefix(directory + "/") else { return nil }
        return String(path.dropFirst(directory.count + 1))
    }

    /// What a change at `relativePath` (as `relativePath(of:...)` writes it) means.
    /// Anything outside `.git` is the working copy. Inside it: `HEAD`, `packed-refs` and
    /// anything under `refs/` move refs and history; `index` is the working copy;
    /// `MERGE_HEAD`, `CHERRY_PICK_HEAD` and anything under `rebase-merge/` or
    /// `rebase-apply/` is an operation; a worktree's entry appearing or going, or another
    /// worktree's `worktrees/<name>/HEAD` moving, is refs (the refs reload lists worktrees).
    /// Lock files, objects and everything else mean nothing.
    public static func classify(relativePath: String) -> Set<GitRepositoryChange> {
        let components = relativePath.split(separator: "/", omittingEmptySubsequences: true)
        guard components.first == ".git" else { return [.workingCopy] }
        let rest = components.dropFirst()
        guard let first = rest.first, let last = rest.last, !last.hasSuffix(".lock") else { return [] }
        let single = rest.count == 1
        switch first {
        case "HEAD" where single, "packed-refs" where single, "refs":
            return [.refs, .history]
        case "index" where single:
            return [.workingCopy]
        case "MERGE_HEAD" where single, "CHERRY_PICK_HEAD" where single, "rebase-merge", "rebase-apply":
            return [.operation]
        case "worktrees" where rest.count == 2,
             "worktrees" where rest.count == 3 && last == "HEAD":
            return [.refs]
        default:
            return []
        }
    }
}
