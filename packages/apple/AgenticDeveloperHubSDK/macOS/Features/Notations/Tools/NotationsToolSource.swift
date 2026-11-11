import Foundation
import AgenticDeveloperHubSDKCore

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
}

/// The `notations_*` tools: read every branch's notes, read or write the
/// notes of the branch the calling pane is on, archive and delete.
///
/// Store and git work runs on the caller's task, never the main actor; only
/// the two lookups into the app's windows and projects hop to main.
public final class NotationsToolSource: ChatToolSource, @unchecked Sendable {

    private let store: NotationsStore
    private let resolver: NotationResolver
    private let git: NotationsGit
    private let callerPlace: @MainActor @Sendable (String) -> NotationsPlace?
    private let projectAtPath: @MainActor @Sendable (String) -> NotationsPlace?

    /// - Parameters:
    ///   - callerPlace: The project and tab working directory of the pane
    ///     with this id, or `nil` for a pane no project window has.
    ///   - projectAtPath: The project whose directory (or one of whose
    ///     worktrees) is this path, or `nil`.
    public init(
        store: NotationsStore,
        git: NotationsGit = NotationsGit(),
        callerPlace: @escaping @MainActor @Sendable (String) -> NotationsPlace?,
        projectAtPath: @escaping @MainActor @Sendable (String) -> NotationsPlace?
    ) {
        self.store = store
        self.git = git
        self.resolver = NotationResolver(git: git, store: store)
        self.callerPlace = callerPlace
        self.projectAtPath = projectAtPath
    }

    // MARK: - Definitions

    public func toolDefinitions() async -> [ToolDefinition] {
        [
            ToolDefinition(
                name: "notations_list",
                description: "Lists notations (per-branch notes) without their content: id, project, branch, "
                    + "state, dates. Optionally filtered by state and by project name or path.",
                parametersJSONSchema: ToolJSONSchema.object(properties: [
                    "state": ToolJSONSchema.string("active or archived; omit for both"),
                    "project": ToolJSONSchema.string("A project name or path; omit for every project")
                ])),
            ToolDefinition(
                name: "notations_get",
                description: "Returns one notation, content included.",
                parametersJSONSchema: ToolJSONSchema.object(
                    properties: ["id": ToolJSONSchema.string("The notation id from notations_list")],
                    required: ["id"])),
            ToolDefinition(
                name: "notations_current",
                description: "Returns the notation of the branch checked out in the calling pane's tab. "
                    + "Content is empty when nothing has been written for the branch yet.",
                parametersJSONSchema: ToolJSONSchema.object(properties: [:])),
            ToolDefinition(
                name: "notations_write",
                description: "Replaces the content of a branch's active notation, creating it if the branch "
                    + "has none. The branch must exist locally.",
                parametersJSONSchema: ToolJSONSchema.object(
                    properties: [
                        "project_path": ToolJSONSchema.string("The project's directory, or a worktree of it"),
                        "branch": ToolJSONSchema.string("The local branch name"),
                        "content": ToolJSONSchema.string("The whole new content, as markdown")
                    ],
                    required: ["project_path", "branch", "content"])),
            ToolDefinition(
                name: "notations_archive",
                description: "Archives an active notation.",
                parametersJSONSchema: ToolJSONSchema.object(
                    properties: ["id": ToolJSONSchema.string("The notation id")],
                    required: ["id"])),
            ToolDefinition(
                name: "notations_delete",
                description: "Deletes an archived notation for good. Active notations are refused.",
                parametersJSONSchema: ToolJSONSchema.object(
                    properties: ["id": ToolJSONSchema.string("The notation id")],
                    required: ["id"]))
        ]
    }

    // MARK: - Calls

    public func callTool(name: String, argumentsJSON: Data, caller: String?) async -> (content: String, isError: Bool) {
        let args = ((try? JSONSerialization.jsonObject(with: argumentsJSON)) as? [String: Any]) ?? [:]
        do {
            switch name {
            case "notations_list": return try list(args)
            case "notations_get": return try get(args)
            case "notations_current": return try await current(caller: caller)
            case "notations_write": return try await write(args)
            case "notations_archive": return try archive(args)
            case "notations_delete": return try delete(args)
            default: return ("unknown tool \(name)", true)
            }
        } catch let error as ToolFailure {
            return (error.message, true)
        } catch {
            return (error.localizedDescription, true)
        }
    }

    private struct ToolFailure: Error { let message: String }

    /// What `notations_list` returns per row: everything but the content.
    private struct Summary: Encodable {
        let id: UUID
        let projectName: String
        let projectPath: String
        let branch: String
        let forkPoint: String
        let state: Notation.State
        let createdAt: Date
        let modifiedAt: Date
        let archivedAt: Date?

        enum CodingKeys: String, CodingKey {
            case id, branch, state
            case projectName = "project_name", projectPath = "project_path", forkPoint = "fork_point"
            case createdAt = "created_at", modifiedAt = "modified_at", archivedAt = "archived_at"
        }

        init(_ notation: Notation) {
            id = notation.id
            projectName = notation.projectName
            projectPath = notation.projectPath
            branch = notation.branch
            forkPoint = notation.forkPoint
            state = notation.state
            createdAt = notation.createdAt
            modifiedAt = notation.modifiedAt
            archivedAt = notation.archivedAt
        }
    }

    private func list(_ args: [String: Any]) throws -> (content: String, isError: Bool) {
        var state: Notation.State?
        if let raw = args["state"] as? String, !raw.isEmpty {
            guard let parsed = Notation.State(rawValue: raw.lowercased()) else {
                throw ToolFailure(message: "state must be active or archived")
            }
            state = parsed
        }
        var notations = try store.all(state: state)
        if let project = (args["project"] as? String)?.trimmingCharacters(in: .whitespaces), !project.isEmpty {
            let path = Self.standardized(project)
            notations = notations.filter {
                $0.projectName.caseInsensitiveCompare(project) == .orderedSame
                    || Self.standardized($0.projectPath) == path
            }
        }
        return Self.encode(notations.map(Summary.init))
    }

    private func get(_ args: [String: Any]) throws -> (content: String, isError: Bool) {
        let id = try Self.id(args)
        guard let notation = try store.notation(id: id) else {
            throw ToolFailure(message: "no notation \(id.uuidString)")
        }
        return Self.encode(notation)
    }

    private func current(caller: String?) async throws -> (content: String, isError: Bool) {
        guard let caller else { throw ToolFailure(message: "the calling pane is unknown") }
        let lookup = callerPlace
        guard let place = await MainActor.run(body: { lookup(caller) }) else {
            throw ToolFailure(message: "the calling pane is not in a Development Project window")
        }
        let resolution = await resolver.resolve(
            projectID: place.projectID, projectName: place.projectName, projectPath: place.projectPath,
            workingDirectory: place.workingDirectory)
        switch resolution {
        case .detached:
            throw ToolFailure(message: "HEAD is detached in \(place.workingDirectory.path); there is no branch")
        case .unavailable(let reason):
            throw ToolFailure(message: "no branch in \(place.workingDirectory.path): \(reason)")
        case .branch(let key, let notation):
            if let notation { return Self.encode(notation) }
            return Self.encode(CurrentUnwritten(key: key))
        }
    }

    /// A branch with nothing written yet: the key it would be written under.
    private struct CurrentUnwritten: Encodable {
        let key: NotationKey
        enum CodingKeys: String, CodingKey {
            case projectName = "project_name", projectPath = "project_path", branch, forkPoint = "fork_point"
            case content, state
        }
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(key.projectName, forKey: .projectName)
            try container.encode(key.projectPath, forKey: .projectPath)
            try container.encode(key.branch, forKey: .branch)
            try container.encode(key.forkPoint, forKey: .forkPoint)
            try container.encode("", forKey: .content)
            try container.encode("unwritten", forKey: .state)
        }
    }

    private func write(_ args: [String: Any]) async throws -> (content: String, isError: Bool) {
        guard let path = (args["project_path"] as? String)?.trimmingCharacters(in: .whitespaces), !path.isEmpty,
              let branch = (args["branch"] as? String)?.trimmingCharacters(in: .whitespaces), !branch.isEmpty,
              let content = args["content"] as? String else {
            throw ToolFailure(message: "project_path, branch and content are required")
        }
        let lookup = projectAtPath
        let standardized = Self.standardized(path)
        guard let place = await MainActor.run(body: { lookup(standardized) }) else {
            throw ToolFailure(message: "no project at \(path)")
        }
        guard try await git.tip(of: branch, in: place.workingDirectory) != nil else {
            throw ToolFailure(message: "there is no local branch \(branch) in \(place.projectName)")
        }
        let (key, existing) = try await resolver.resolve(
            branch: branch, projectID: place.projectID, projectName: place.projectName,
            projectPath: place.projectPath, workingDirectory: place.workingDirectory)
        let saved = try store.save(id: existing?.id, key: key, content: content)
        return Self.encode(saved)
    }

    private func archive(_ args: [String: Any]) throws -> (content: String, isError: Bool) {
        let id = try Self.id(args)
        guard try store.archive(id: id) else {
            throw ToolFailure(message: "no active notation \(id.uuidString)")
        }
        guard let notation = try store.notation(id: id) else {
            throw ToolFailure(message: "no notation \(id.uuidString)")
        }
        return Self.encode(Summary(notation))
    }

    private func delete(_ args: [String: Any]) throws -> (content: String, isError: Bool) {
        let id = try Self.id(args)
        do {
            guard try store.deleteArchived(id: id) else {
                throw ToolFailure(message: "no notation \(id.uuidString)")
            }
        } catch NotationsStoreError.notArchived {
            throw ToolFailure(message: "notation \(id.uuidString) is active; archive it first")
        }
        return ("deleted \(id.uuidString)", false)
    }

    // MARK: - Helpers

    private static func id(_ args: [String: Any]) throws -> UUID {
        guard let raw = args["id"] as? String, let id = UUID(uuidString: raw) else {
            throw ToolFailure(message: "id must be a notation id")
        }
        return id
    }

    static func standardized(_ path: String) -> String {
        URL(fileURLWithPath: (path as NSString).expandingTildeInPath).standardizedFileURL.path
    }

    private static func encode(_ value: some Encodable) -> (content: String, isError: Bool) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(value), let text = String(data: data, encoding: .utf8) else {
            return ("could not encode the result", true)
        }
        return (text, false)
    }
}
