import AppKit

/// A listed project, as Cocoa Scripting sees it — whether or not a window has
/// it open. Holds a copy of the row: a project is data, and the id is what a
/// script keeps across renames and relaunches.
@MainActor
@objc(ScriptableProject)
public final class ScriptableProject: NSObject {

    public let repo: GitRepo

    public init(repo: GitRepo) {
        self.repo = repo
        super.init()
    }

    @objc var uniqueID: String { repo.id.uuidString }
    @objc var name: String { repo.name }
    @objc var path: String { repo.path }
    @objc var remote: String { repo.remote ?? "" }
    @objc var lastOpened: Date? { repo.lastOpened }
    @objc var isOpen: Bool { ProjectWindowManager.shared.group(containing: repo.id) != nil }

    public override nonisolated var objectSpecifier: NSScriptObjectSpecifier? {
        applicationElementSpecifier(key: "projects") { self.uniqueID }
    }
}

extension ProjectWindowManager {

    /// Every project the Project Browser lists.
    public var scriptableProjects: [ScriptableProject] {
        listedProjects.map(ScriptableProject.init(repo:))
    }

    public func scriptableProject(uniqueID: String) -> ScriptableProject? {
        listedProjects.first { $0.id.uuidString == uniqueID }.map(ScriptableProject.init(repo:))
    }

    private var listedProjects: [GitRepo] {
        (coordinator?.listedRepos ?? []).filter { $0.kind == .project }
    }

    /// A project named by id, path (`~` expanded) or name, in that order: an
    /// id is unambiguous, a path nearly so, and a name is what a person types.
    public func listedProject(matching reference: String) -> GitRepo? {
        let repos = listedProjects
        let trimmed = reference.trimmingCharacters(in: .whitespacesAndNewlines)
        let path = URL(fileURLWithPath: (trimmed as NSString).expandingTildeInPath).standardizedFileURL.path
        return repos.first { $0.id.uuidString.caseInsensitiveCompare(trimmed) == .orderedSame }
            ?? repos.first { URL(fileURLWithPath: $0.path).standardizedFileURL.path == path }
            ?? repos.first { $0.name == trimmed }
            ?? repos.first { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }
    }
}

/// AppleScript command: `open project "<id, path or name>"` — what clicking
/// the project in the front window's Project Browser does.
@objc(OpenProjectCommand)
public final class OpenProjectCommand: MainActorScriptCommand, @unchecked Sendable {
    public override func performMain() -> Any? {
        let reference: String?
        if let text = directParameter as? String {
            reference = text
        } else if let url = directParameter as? URL {
            reference = url.path
        } else {
            reference = nil
        }
        guard let reference, !reference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            scriptErrorNumber = errOSACantAssign
            scriptErrorString = "A project id, path or name is required."
            return nil
        }
        guard let repo = ProjectWindowManager.shared.listedProject(matching: reference) else {
            scriptErrorNumber = errOSACantAssign
            scriptErrorString = "No listed project matches “\(reference)”."
            return nil
        }
        ProjectWindowManager.shared.openProjectForScripting(repo)
        return ScriptableProject(repo: repo)
    }
}
