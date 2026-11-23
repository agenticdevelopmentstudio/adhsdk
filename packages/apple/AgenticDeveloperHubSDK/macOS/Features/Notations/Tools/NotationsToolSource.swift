import Foundation
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKDatabase

/// The `notations_*` tools for in-process chat: the window-free data tools
/// (`NotationsDataTools`: list, get, write, archive, delete), plus
/// `notations_current`, which reads the notes of the branch the calling
/// pane's tab is on and so needs the app's windows.
///
/// Store and git work runs on the caller's task, never the main actor; only
/// the two lookups into the app's windows and projects hop to main.
public final class NotationsToolSource: ChatToolSource, @unchecked Sendable {

    public static let currentToolName = "notations_current"

    private let data: NotationsDataTools
    private let resolver: NotationResolver
    private let callerPlace: @MainActor @Sendable (String) -> NotationsPlace?

    /// - Parameters:
    ///   - callerPlace: The project and tab working directory of the pane
    ///     with this id, or `nil` for a pane no project window has.
    ///   - projectAtPath: The project whose directory (or one of whose
    ///     worktrees) is this path, or `nil`.
    public init(
        store: any NotationsStoring,
        git: NotationsGit = NotationsGit(),
        callerPlace: @escaping @MainActor @Sendable (String) -> NotationsPlace?,
        projectAtPath: @escaping @MainActor @Sendable (String) -> NotationsPlace?
    ) {
        self.data = NotationsDataTools(store: store, git: git, projectAtPath: { path in
            await MainActor.run { projectAtPath(path) }
        })
        self.resolver = NotationResolver(git: git, store: store)
        self.callerPlace = callerPlace
    }

    // MARK: - Definitions

    public func toolDefinitions() async -> [ToolDefinition] {
        var definitions = await data.toolDefinitions()
        let current = ToolDefinition(
            name: Self.currentToolName,
            description: "Returns the notation of the branch checked out in the calling pane's tab. "
                + "Content is empty when nothing has been written for the branch yet.",
            parametersJSONSchema: ToolJSONSchema.object(properties: [:]))
        // After `notations_get`, where the list has always had it.
        let index = definitions.firstIndex { $0.name == "notations_get" }.map { $0 + 1 } ?? definitions.endIndex
        definitions.insert(current, at: index)
        return definitions
    }

    // MARK: - Calls

    public func callTool(name: String, argumentsJSON: Data, caller: String?) async -> (content: String, isError: Bool) {
        guard name == Self.currentToolName else {
            return await data.callTool(name: name, argumentsJSON: argumentsJSON, caller: caller)
        }
        do {
            return try await current(caller: caller)
        } catch let error as NotationsDataTools.Failure {
            return (error.message, true)
        } catch {
            return (error.localizedDescription, true)
        }
    }

    private func current(caller: String?) async throws -> (content: String, isError: Bool) {
        guard let caller else { throw NotationsDataTools.Failure(message: "the calling pane is unknown") }
        let lookup = callerPlace
        guard let place = await MainActor.run(body: { lookup(caller) }) else {
            throw NotationsDataTools.Failure(message: "the calling pane is not in a Coding Project window")
        }
        let resolution = await resolver.resolve(
            projectID: place.projectID, projectName: place.projectName, projectPath: place.projectPath,
            workingDirectory: place.workingDirectory)
        switch resolution {
        case .detached:
            throw NotationsDataTools.Failure(
                message: "HEAD is detached in \(place.workingDirectory.path); there is no branch")
        case .unavailable(let reason):
            throw NotationsDataTools.Failure(message: "no branch in \(place.workingDirectory.path): \(reason)")
        case .branch(let key, let notation):
            if let notation { return NotationsDataTools.encode(notation) }
            return NotationsDataTools.encode(CurrentUnwritten(key: key))
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
}
