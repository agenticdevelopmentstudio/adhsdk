import Foundation

extension GitClient {

    /// `ref`'s reflog, newest first, at most `limit` entries (recipe
    /// `foundation/git/git-client`, "Reflog"): `git reflog show --no-show-signature -z
    /// --format=GitReflogEntry.format -n <limit> <ref>`.
    ///
    /// A ref with no reflog yet (an unborn HEAD in a repository with no commit) is an
    /// empty list rather than an error; any other failure throws. A ref starting with `-`
    /// is refused before git runs, so it can never be read as an option.
    public func reflog(ref: String = "HEAD", limit: Int = 200, in directory: URL,
                       caller: GitCaller = GitCaller()) async throws -> [GitReflogEntry] {
        guard !ref.hasPrefix("-") else { throw GitClientError.invalidArgument(verb: "reflog", argument: ref) }
        let arguments = ["show", "--no-show-signature", "-z", "--format=\(GitReflogEntry.format)",
                         "-n", "\(max(limit, 1))", ref]
        do {
            let output = try await run("reflog", arguments, in: directory, caller: caller)
            return GitReflogEntry.parse(reflog: output)
        } catch let error as GitClientError {
            guard case .commandFailed(_, 128, _) = error,
                  try await resolveCommit(ref, in: directory, caller: caller) == nil else {
                throw error
            }
            return []
        }
    }
}
