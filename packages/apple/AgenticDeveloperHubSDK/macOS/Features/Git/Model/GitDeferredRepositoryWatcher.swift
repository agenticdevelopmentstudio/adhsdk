import Foundation
import AgenticDeveloperHubSDKCore
import os

/// A `GitRepositoryWatcher` whose git and common directories are asked of git first,
/// so a window can be made synchronously (launch restore) and still watch a linked
/// worktree's real directories. Stopped before git answers, it never starts; started
/// again, it stops the watcher it made and only the latest start makes another.
@MainActor
final class GitDeferredRepositoryWatcher: GitRepositoryWatching {
    private let root: URL
    private let client: GitClient
    private let makeWatcher: @MainActor (_ root: URL, _ gitDirectory: URL, _ commonDirectory: URL)
        -> GitRepositoryWatching
    private var watcher: GitRepositoryWatching?
    private var isStopped = false
    /// Counts `start`s, so only the latest one's answer from git makes a watcher.
    private var startToken = 0
    /// The task asking git for the directories; tests await it.
    private(set) var beginTask: Task<Void, Never>?

    init(root: URL, client: GitClient,
         makeWatcher: @escaping @MainActor (_ root: URL, _ gitDirectory: URL, _ commonDirectory: URL)
             -> GitRepositoryWatching = { GitRepositoryWatcher(root: $0, gitDirectory: $1, commonDirectory: $2) }) {
        self.root = root
        self.client = client
        self.makeWatcher = makeWatcher
    }

    nonisolated func start(onChange: @escaping @Sendable (Set<GitRepositoryChange>) -> Void) {
        MainActor.assumeIsolated { self.begin(onChange: onChange) }
    }

    nonisolated func stop() {
        MainActor.assumeIsolated {
            self.isStopped = true
            self.watcher?.stop()
            self.watcher = nil
        }
    }

    private func begin(onChange: @escaping @Sendable (Set<GitRepositoryChange>) -> Void) {
        isStopped = false
        startToken += 1
        let token = startToken
        watcher?.stop()
        watcher = nil
        let root = root
        let client = client
        beginTask = Task { [weak self] in
            let gitDirectory: URL
            let commonDirectory: URL
            do {
                gitDirectory = try await Self.directory("--git-dir", of: root, client: client)
                commonDirectory = try await Self.directory("--git-common-dir", of: root, client: client)
            } catch {
                Self.logger.error(
                    "Could not find the git directories: \(GitClientError.logDescription(of: error), privacy: .public)")
                return
            }
            guard let self, !self.isStopped, token == self.startToken else { return }
            let watcher = self.makeWatcher(root, gitDirectory, commonDirectory)
            self.watcher = watcher
            watcher.start(onChange: onChange)
        }
    }

    /// One absolute directory git reports for `option`, asked on its own so a path
    /// with a newline in it is read whole; only git's trailing newline is dropped.
    static func directory(_ option: String, of root: URL, client: GitClient) async throws -> URL {
        var path = try await client.run("rev-parse", ["--path-format=absolute", option], in: root)
        if path.hasSuffix("\n") { path.removeLast() }
        return URL(fileURLWithPath: path, isDirectory: true)
    }
}

extension GitDeferredRepositoryWatcher: Loggable {
    static nonisolated let logger = makeLogger()
}
