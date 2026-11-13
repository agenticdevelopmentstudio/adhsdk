import AppKit
import AgenticDeveloperHubSDKCore

/// How Notations finds projects in the Projects feature: the pane a tool was
/// called from, the project a path is in, the project a window shows, and
/// bringing a notation's project forward. Kept apart from `NotationsFeature`
/// so the feature takes them as closures and its tests need no windows
/// (`dependency-injection`).
@MainActor
public enum NotationsProjectLookups {

    /// The project and tab working directory of the pane whose layout node
    /// id is `caller` (what a terminal sends as `ADKITCHEN_PANE_ID`).
    public static func callerPlace(_ caller: String) -> NotationsPlace? {
        guard let nodeID = UUID(uuidString: caller) else { return nil }
        for controller in ProjectWindowManager.shared.openWindowControllers {
            guard let pane = controller.allPanes().first(where: { $0.nodeID == nodeID }) else { continue }
            let project = controller.project
            let directory = controller.workingDirectory(ofTabContaining: pane) ?? project.directoryURL
            return NotationsPlace(projectID: project.id, projectName: project.repo.name,
                                  projectPath: project.repo.path, workingDirectory: directory)
        }
        return nil
    }

    /// The listed project whose directory holds `path` — the deepest one, so
    /// a worktree nested in its project's folder resolves to that project.
    public static func projectAtPath(_ path: String, in repos: [GitRepo]) -> NotationsPlace? {
        let target = URL(fileURLWithPath: (path as NSString).expandingTildeInPath).standardizedFileURL.path
        let match = repos
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

    /// The project a Coding Project window shows; `nil` for any other
    /// window, a File Browser window included.
    public static func projectID(for window: NSWindow) -> UUID? {
        guard let controller = window.windowController as? ComposableTabsWindowController else { return nil }
        let id = controller.project.id
        return ProjectWindowManager.shared.isFileBrowserWindow(id) ? nil : id
    }

    /// Brings the notation's project forward, opening it when it is listed
    /// but not open.
    public static func goToProject(_ notation: Notation, in repos: [GitRepo]) {
        if let repo = repos.first(where: { $0.id == notation.projectID }) {
            ProjectWindowManager.shared.openProject(repo)
        } else if ProjectWindowManager.shared.windowController(for: notation.projectID) != nil {
            ProjectWindowManager.shared.reveal(notation.projectID)
        }
    }
}
