#if canImport(AgenticDeveloperHubSDKCore)

import Foundation

/// Where a notation is resolved: a project, and the checkout inside it whose
/// branch counts (the project's own directory, or one of its worktrees).
public struct NotationsPlace: Sendable, Equatable {
    public var projectID: UUID
    public var projectName: String
    public var projectPath: String
    public var workingDirectory: URL

    public init(projectID: UUID, projectName: String, projectPath: String, workingDirectory: URL) {
        self.projectID = projectID
        self.projectName = projectName
        self.projectPath = projectPath
        self.workingDirectory = workingDirectory
    }

    /// The project in `projects` whose directory holds `path` — the deepest
    /// one, so a worktree nested in its project's folder resolves to that
    /// project — with `path` as the working directory. `nil` when none does.
    /// Rows of any kind but `project` are ignored.
    public static func project(containing path: String, in projects: [GitRepo]) -> NotationsPlace? {
        let target = standardized(path)
        let match = projects
            .filter { $0.kind == .project }
            .filter { repo in
                let root = URL(fileURLWithPath: repo.path).standardizedFileURL.path
                return target == root || target.hasPrefix(root.hasSuffix("/") ? root : root + "/")
            }
            .max { $0.path.count < $1.path.count }
        guard let match else { return nil }
        return NotationsPlace(projectID: match.id, projectName: match.name, projectPath: match.path,
                              workingDirectory: URL(fileURLWithPath: target))
    }

    /// `path` with `~` expanded and `.`/`..` resolved.
    public static func standardized(_ path: String) -> String {
        URL(fileURLWithPath: (path as NSString).expandingTildeInPath).standardizedFileURL.path
    }
}

#endif
