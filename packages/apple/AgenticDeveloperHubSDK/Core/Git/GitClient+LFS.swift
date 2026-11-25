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
    ///
    /// `lfs version` is asked once per git executable (see `lfsInstalledFor`), and `track`
    /// and `ls-files` run side by side: each is a few hundred milliseconds, and the model
    /// asks on every refresh.
    public func lfsState(in directory: URL, caller: GitCaller = GitCaller()) async throws -> GitLFSState {
        let executable = await configurationProvider().executableURL.path
        if !lfsInstalledFor.contains(executable) {
            do {
                _ = try await run("lfs", ["version"], in: directory, caller: caller)
            } catch GitClientError.commandFailed {
                return .notInstalled
            }
            lfsInstalledFor.insert(executable)
        }
        async let trackOutput = run("lfs", ["track"], in: directory, caller: caller)
        async let filesOutput = run("lfs", ["ls-files"], in: directory, caller: caller)
        let files = (try? await filesOutput) ?? ""
        let track = try await trackOutput
        return GitLFSState(
            isInstalled: true,
            trackedPatterns: GitLFSState.parseTrackedPatterns(track),
            files: GitLFSState.parseFiles(files))
    }
}
