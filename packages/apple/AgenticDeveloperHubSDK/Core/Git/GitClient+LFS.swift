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
    /// on the next look rather than a thrown `track` failure.
    ///
    /// Neither runs when no attribute source names `filter=lfs` (see `namesLFSFilter`):
    /// then no path here is checked out through LFS, and the state is empty. That
    /// includes `files`, although `ls-files` would still list a pointer committed while a
    /// rule named the filter, after every such rule was removed: git checks such a file
    /// out as its pointer text, and the state leaves it out.
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

    /// Whether any attribute source git reads for LFS mentions `filter=lfs`: every
    /// `.gitattributes` in the working tree or the index that is not ignored, tracked or
    /// not and at any depth, the repository's `info/attributes`, and the global and system
    /// attributes files. A handful of plain git reads of a few milliseconds each, in place
    /// of two `git-lfs` launches.
    ///
    /// A `.gitattributes` the index lists but the working tree lacks (a non-cone sparse
    /// checkout leaves it out, or it was deleted without staging) is read from the index,
    /// as git and git-lfs read it. A git that cannot say where the global or system file
    /// is (`git var` before 2.42) answers yes, so `git lfs track` decides.
    ///
    /// A substring test, so a comment that mentions the filter only costs the `git-lfs`
    /// calls it would have made anyway. A file that cannot be read counts as naming it.
    /// The files are read on a GCD queue (`BlockingWork`), never on this actor, so a
    /// repository on a hung network volume does not hold up every other caller's git.
    private func namesLFSFilter(in directory: URL, caller: GitCaller) async throws -> Bool {
        async let listed = run(
            "ls-files", ["-z", "--cached", "--others", "--exclude-standard", "--",
                         ":(top,glob)**/.gitattributes"],
            in: directory, caller: caller)
        async let infoPath = run("rev-parse", ["--git-path", "info/attributes"], in: directory, caller: caller)
        async let globalPath = attributesFile("GIT_ATTR_GLOBAL", in: directory, caller: caller)
        async let systemPath = attributesFile("GIT_ATTR_SYSTEM", in: directory, caller: caller)
        let listedPaths = try await listed.split(separator: "\0").map(String.init)
        var paths = listedPaths.map { directory.appendingPathComponent($0) }
        let info = try await infoPath.trimmingCharacters(in: .newlines)
        // Relative to `directory` unless it is absolute (a linked worktree's is).
        if !info.isEmpty {
            paths.append(info.hasPrefix("/") ? URL(fileURLWithPath: info) : directory.appendingPathComponent(info))
        }
        guard let global = try await globalPath, let system = try await systemPath else { return true }
        for path in [global, system] where !path.isEmpty {
            paths.append(URL(fileURLWithPath: path))
        }
        let files = paths
        let readings = await BlockingWork.run { files.map { GitClient.attributesReading($0) } }
        if readings.contains(.names) { return true }
        // A listed `.gitattributes` missing from the working tree: the index's copy.
        for (index, path) in listedPaths.enumerated() where readings[index] == .missing {
            // `:./` makes the path relative to `directory`, as `ls-files` printed it.
            do {
                let text = try await run("cat-file", ["blob", ":./\(path)"], in: directory, caller: caller)
                if text.contains("filter=lfs") { return true }
            } catch GitClientError.commandFailed {
                // Untracked and gone since it was listed: it names nothing.
                continue
            }
        }
        return false
    }

    /// The file `git var <variable>` names; `""` when git says there is none (exit 1, as
    /// under `GIT_ATTR_NOSYSTEM`), `nil` when this git cannot say (a git before 2.42
    /// answers its usage, exit 129, or any other failure).
    private func attributesFile(_ variable: String, in directory: URL, caller: GitCaller) async throws -> String? {
        do {
            return try await run("var", [variable], in: directory, caller: caller)
                .trimmingCharacters(in: .newlines)
        } catch GitClientError.commandFailed(_, 1, _) {
            return ""
        } catch GitClientError.commandFailed {
            return nil
        }
    }

    /// What reading one attributes file found.
    enum AttributesReading: Sendable, Equatable {
        case names, omits, missing
    }

    static func attributesReading(_ file: URL) -> AttributesReading {
        guard FileManager.default.fileExists(atPath: file.path) else { return .missing }
        guard let data = try? Data(contentsOf: file) else { return .names }
        return data.range(of: Data("filter=lfs".utf8)) != nil ? .names : .omits
    }
}
