import Foundation

/// The environment every git child gets (recipe `foundation/git/git-client`, "LFS").
extension GitClient {

    /// What git's child merges over the parent's environment: `baseEnvironment`, then a
    /// repaired `PATH`, then the configuration's extra environment, then `environment`.
    ///
    /// The `PATH` is `ExecutableLocator`'s search directories (the inherited `PATH`, then
    /// the Homebrew and `/usr/local` install directories), as `GitHubCLI` uses. An app
    /// launched from Finder or launchd inherits only the system directories, and git looks
    /// up `git-lfs` and other `git-<name>` helpers on `PATH`, so without it a Homebrew
    /// git-lfs is invisible and LFS reads as not installed.
    static func childEnvironment(
        configuration: GitClientConfiguration,
        environment: [String: String],
        parent: [String: String] = ProcessInfo.processInfo.environment
    ) -> [String: String] {
        let path = ExecutableLocator(environment: parent).searchDirectories.joined(separator: ":")
        return baseEnvironment
            .merging(["PATH": path]) { _, override in override }
            .merging(configuration.extraEnvironment) { _, override in override }
            .merging(environment) { _, override in override }
    }
}
