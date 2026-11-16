import Foundation

extension GitClient {

    /// Whether `directory`'s repository uses Git LFS (recipe `foundation/git/git-client`,
    /// "LFS"): `git lfs version`, then `git lfs track` and `git lfs ls-files`. git finds
    /// `git-lfs` itself, on the `PATH` every child inherits.
    ///
    /// Never throws for git-lfs not being installed: a failed `lfs version` (git answers
    /// "'lfs' is not a git command") returns `GitLFSState.notInstalled`. `ls-files` fails in
    /// a repository with no commit yet, which lists no files rather than throwing. A failure
    /// of `track`, or git itself missing, throws.
    public func lfsState(in directory: URL, caller: GitCaller = GitCaller()) async throws -> GitLFSState {
        do {
            _ = try await run("lfs", ["version"], in: directory, caller: caller)
        } catch GitClientError.commandFailed {
            return .notInstalled
        }
        let track = try await run("lfs", ["track"], in: directory, caller: caller)
        let files = (try? await run("lfs", ["ls-files"], in: directory, caller: caller)) ?? ""
        return GitLFSState(
            isInstalled: true,
            trackedPatterns: GitLFSState.parseTrackedPatterns(track),
            files: GitLFSState.parseFiles(files))
    }
}
