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
    /// asks on every refresh. A `track` that fails drops the remembered yes and asks
    /// `lfs version` again, so git-lfs uninstalled while the app runs is `.notInstalled`
    /// on the next look rather than a thrown `track` failure. Neither runs when no attribute source names `filter=lfs`
    /// (see `namesLFSFilter`): then LFS manages nothing here, and the state is empty.
    public func lfsState(in directory: URL, caller: GitCaller = GitCaller()) async throws -> GitLFSState {
        let executable = await configurationProvider().executableURL.path
        if !lfsInstalledFor.contains(executable) {
            guard try await lfsAnswersVersion(in: directory, caller: caller) else { return .notInstalled }
            lfsInstalledFor.insert(executable)
        }
        guard try await namesLFSFilter(in: directory, caller: caller) else {
            return GitLFSState(isInstalled: true, trackedPatterns: [], files: [:])
        }
        async let trackOutput = run("lfs", ["track"], in: directory, caller: caller)
        async let filesOutput = run("lfs", ["ls-files"], in: directory, caller: caller)
        let files = (try? await filesOutput) ?? ""
        let track: String
        do {
            track = try await trackOutput
        } catch let error as GitClientError {
            guard case .commandFailed = error else { throw error }
            // The remembered yes may be stale: git-lfs uninstalled since it was asked.
            lfsInstalledFor.remove(executable)
            guard try await lfsAnswersVersion(in: directory, caller: caller) else { return .notInstalled }
            lfsInstalledFor.insert(executable)
            throw error
        }
        return GitLFSState(
            isInstalled: true,
            trackedPatterns: GitLFSState.parseTrackedPatterns(track),
            files: GitLFSState.parseFiles(files))
    }

    /// Whether `git lfs version` exits 0; false for the failure git gives when git-lfs is
    /// not installed. Git itself missing, or a timeout, still throws.
    private func lfsAnswersVersion(in directory: URL, caller: GitCaller) async throws -> Bool {
        do {
            _ = try await run("lfs", ["version"], in: directory, caller: caller)
            return true
        } catch GitClientError.commandFailed {
            return false
        }
    }

    /// Whether any attribute source `git lfs track` reads mentions `filter=lfs`: every
    /// `.gitattributes` in the working tree that is not ignored, tracked or not and at any
    /// depth, the repository's `info/attributes`, and the global attributes file. Three
    /// plain git reads of a few milliseconds each, in place of two `git-lfs` launches.
    ///
    /// A substring test, so a comment that mentions the filter only costs the `git-lfs`
    /// calls it would have made anyway. A file that cannot be read counts as naming it.
    private func namesLFSFilter(in directory: URL, caller: GitCaller) async throws -> Bool {
        async let listed = run(
            "ls-files", ["-z", "--cached", "--others", "--exclude-standard", "--",
                         ":(top,glob)**/.gitattributes"],
            in: directory, caller: caller)
        async let infoPath = run("rev-parse", ["--git-path", "info/attributes"], in: directory, caller: caller)
        async let globalPath = run("var", ["GIT_ATTR_GLOBAL"], in: directory, caller: caller)
        var paths = try await listed.split(separator: "\0").map { directory.appendingPathComponent(String($0)) }
        let info = try await infoPath.trimmingCharacters(in: .newlines)
        // Relative to `directory` unless it is absolute (a linked worktree's is).
        if !info.isEmpty {
            paths.append(info.hasPrefix("/") ? URL(fileURLWithPath: info) : directory.appendingPathComponent(info))
        }
        // `git var` fails when there is no home to put the file in; then there is none.
        let global = ((try? await globalPath) ?? "").trimmingCharacters(in: .newlines)
        if !global.isEmpty { paths.append(URL(fileURLWithPath: global)) }
        return paths.contains { Self.mentionsLFSFilter($0) }
    }

    private static func mentionsLFSFilter(_ file: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: file.path) else { return false }
        guard let data = try? Data(contentsOf: file) else { return true }
        return data.range(of: Data("filter=lfs".utf8)) != nil
    }
}
