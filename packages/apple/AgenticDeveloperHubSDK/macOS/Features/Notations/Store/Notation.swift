import Foundation

/// One branch's notes: what the Notations pane edits, the Notations window
/// lists, and the `notations_*` tools and the AppleScript `notation` class
/// read and write.
///
/// A git branch has no identity beyond its name, so a notation derives one:
/// `(projectID, branch, forkPoint)`, the fork point being
/// `git merge-base <default branch> <branch>` when the notation was created.
/// A same-named branch made later forks from a different commit and so gets
/// a notation of its own, while the old one stays archived.
public struct Notation: Sendable, Equatable, Identifiable, Codable {

    public enum State: String, Sendable, Codable, CaseIterable {
        case active
        case archived
    }

    public let id: UUID
    public let projectID: UUID
    public var projectName: String
    public var projectPath: String
    public let branch: String
    public let forkPoint: String
    /// The branch tip the last reconcile saw; `nil` until one has run.
    public var lastTip: String?
    public var content: String
    public var state: State
    public let createdAt: Date
    public var modifiedAt: Date
    public var archivedAt: Date?

    public init(
        id: UUID = UUID(),
        projectID: UUID,
        projectName: String,
        projectPath: String,
        branch: String,
        forkPoint: String,
        lastTip: String? = nil,
        content: String,
        state: State = .active,
        createdAt: Date,
        modifiedAt: Date,
        archivedAt: Date? = nil
    ) {
        self.id = id
        self.projectID = projectID
        self.projectName = projectName
        self.projectPath = projectPath
        self.branch = branch
        self.forkPoint = forkPoint
        self.lastTip = lastTip
        self.content = content
        self.state = state
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.archivedAt = archivedAt
    }

    /// Snake case, as the table's columns are, so a tool's JSON reads like
    /// the store it came from.
    enum CodingKeys: String, CodingKey {
        case id
        case projectID = "project_id"
        case projectName = "project_name"
        case projectPath = "project_path"
        case branch
        case forkPoint = "fork_point"
        case lastTip = "last_tip"
        case content
        case state
        case createdAt = "created_at"
        case modifiedAt = "modified_at"
        case archivedAt = "archived_at"
    }
}

/// What a notation is keyed by before it has a row: the pane knows it as soon
/// as it has resolved its branch, and writes nothing until the first edit.
public struct NotationKey: Sendable, Equatable, Hashable {
    public let projectID: UUID
    public let projectName: String
    public let projectPath: String
    public let branch: String
    public let forkPoint: String

    public init(projectID: UUID, projectName: String, projectPath: String, branch: String, forkPoint: String) {
        self.projectID = projectID
        self.projectName = projectName
        self.projectPath = projectPath
        self.branch = branch
        self.forkPoint = forkPoint
    }
}
