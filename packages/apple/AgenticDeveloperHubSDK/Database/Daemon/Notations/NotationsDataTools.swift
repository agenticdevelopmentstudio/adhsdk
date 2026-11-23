#if canImport(AgenticDeveloperHubSDKCore)

import Foundation
import AgenticDeveloperHubSDKCore

/// The `notations_*` tools that need no window: read every branch's notes,
/// write a named branch's notes, archive and delete.
///
/// Core-only, so the same tools run in an app's chat (composed by the macOS
/// `NotationsToolSource`, which adds `notations_current`) and in adhd (served
/// as app `notations`). Every store and git call runs on the caller's task.
public struct NotationsDataTools: ChatToolSource {

    /// The names this source answers.
    public static let toolNames: Set<String> = [
        "notations_list", "notations_get", "notations_write", "notations_archive", "notations_delete"
    ]

    private let store: any NotationsStoring
    private let git: NotationsGit
    private let resolver: NotationResolver
    private let projectAtPath: @Sendable (String) async -> NotationsPlace?

    /// - Parameter projectAtPath: The project whose directory (or one of
    ///   whose worktrees) is this standardized path, or `nil`.
    ///   `NotationsPlace.project(containing:in:)` answers it from a list.
    public init(
        store: any NotationsStoring,
        git: NotationsGit = NotationsGit(),
        projectAtPath: @escaping @Sendable (String) async -> NotationsPlace?
    ) {
        self.store = store
        self.git = git
        self.resolver = NotationResolver(git: git, store: store)
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
            case "notations_list": return try await list(args)
            case "notations_get": return try await get(args)
            case "notations_write": return try await write(args)
            case "notations_archive": return try await archive(args)
            case "notations_delete": return try await delete(args)
            default: return ("unknown tool \(name)", true)
            }
        } catch let error as Failure {
            return (error.message, true)
        } catch {
            return (error.localizedDescription, true)
        }
    }

    /// A refusal whose message is the tool's whole answer.
    public struct Failure: Error, Equatable {
        public let message: String
        public init(message: String) { self.message = message }
    }

    /// What `notations_list` and `notations_archive` return per row:
    /// everything but the content.
    struct Summary: Encodable {
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

    private func list(_ args: [String: Any]) async throws -> (content: String, isError: Bool) {
        var state: Notation.State?
        if let raw = args["state"] as? String, !raw.isEmpty {
            guard let parsed = Notation.State(rawValue: raw.lowercased()) else {
                throw Failure(message: "state must be active or archived")
            }
            state = parsed
        }
        var notations = try await store.all(state: state)
        if let project = (args["project"] as? String)?.trimmingCharacters(in: .whitespaces), !project.isEmpty {
            let path = NotationsPlace.standardized(project)
            notations = notations.filter {
                $0.projectName.caseInsensitiveCompare(project) == .orderedSame
                    || NotationsPlace.standardized($0.projectPath) == path
            }
        }
        return Self.encode(notations.map(Summary.init))
    }

    private func get(_ args: [String: Any]) async throws -> (content: String, isError: Bool) {
        let id = try Self.id(args)
        guard let notation = try await store.notation(id: id) else {
            throw Failure(message: "no notation \(id.uuidString)")
        }
        return Self.encode(notation)
    }

    private func write(_ args: [String: Any]) async throws -> (content: String, isError: Bool) {
        guard let path = (args["project_path"] as? String)?.trimmingCharacters(in: .whitespaces), !path.isEmpty,
              let branch = (args["branch"] as? String)?.trimmingCharacters(in: .whitespaces), !branch.isEmpty,
              let content = args["content"] as? String else {
            throw Failure(message: "project_path, branch and content are required")
        }
        guard let place = await projectAtPath(NotationsPlace.standardized(path)) else {
            throw Failure(message: "no project at \(path)")
        }
        guard try await git.tip(of: branch, in: place.workingDirectory) != nil else {
            throw Failure(message: "there is no local branch \(branch) in \(place.projectName)")
        }
        let (key, existing) = try await resolver.resolve(
            branch: branch, projectID: place.projectID, projectName: place.projectName,
            projectPath: place.projectPath, workingDirectory: place.workingDirectory)
        let saved = try await store.save(id: existing?.id, key: key, content: content)
        return Self.encode(saved)
    }

    private func archive(_ args: [String: Any]) async throws -> (content: String, isError: Bool) {
        let id = try Self.id(args)
        guard try await store.archive(id: id) else {
            throw Failure(message: "no active notation \(id.uuidString)")
        }
        guard let notation = try await store.notation(id: id) else {
            throw Failure(message: "no notation \(id.uuidString)")
        }
        return Self.encode(Summary(notation))
    }

    private func delete(_ args: [String: Any]) async throws -> (content: String, isError: Bool) {
        let id = try Self.id(args)
        do {
            guard try await store.deleteArchived(id: id) else {
                throw Failure(message: "no notation \(id.uuidString)")
            }
        } catch NotationsStoreError.notArchived {
            throw Failure(message: "notation \(id.uuidString) is active; archive it first")
        }
        return ("deleted \(id.uuidString)", false)
    }

    // MARK: - Helpers

    private static func id(_ args: [String: Any]) throws -> UUID {
        guard let raw = args["id"] as? String, let id = UUID(uuidString: raw) else {
            throw Failure(message: "id must be a notation id")
        }
        return id
    }

    /// A tool answer: `value` as sorted, pretty JSON with ISO 8601 dates.
    public static func encode(_ value: some Encodable) -> (content: String, isError: Bool) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(value), let text = String(data: data, encoding: .utf8) else {
            return ("could not encode the result", true)
        }
        return (text, false)
    }
}

#endif
