import Foundation
import AgenticDeveloperHubSDKCore

/// The app's Terminal Chats as tools: Claude Code, in another terminal, lists
/// them, types a command into one and reads the reply, through the MCP tools
/// the app serves — the protocol ``TerminalChatControl`` defines, with no
/// socket of its own.
///
/// Everything goes through the chat, never the terminal, so it shows in the
/// chat's transcript as it happens — and a chat connected to a private
/// terminal reads back only what that terminal shows, its privacy words in
/// place of the real ones.
///
/// Which chat a call means is `TerminalChatControl.resolve`'s answer (an id
/// prefix, or nothing when exactly one chat is open), and every wait is
/// clamped to `TerminalChatControl.Defaults`' limits.
public final class TerminalChatDirectoryToolSource: ChatToolSource, @unchecked Sendable {

    public enum ToolName {
        public static let list = "list"
        public static let run = "run"
        public static let wait = "wait"
        public static let interrupt = "interrupt"
        public static let screen = "screen"
    }

    private let directory: any TerminalChatListing

    public init(directory: any TerminalChatListing) {
        self.directory = directory
    }

    // MARK: - Definitions

    public func toolDefinitions() async -> [ToolDefinition] {
        typealias Defaults = TerminalChatControl.Defaults
        let chat = ToolJSONSchema.string(
            "The chat's id, or the start of it. May be left out when exactly one Terminal Chat is open.")
        let settle = ToolJSONSchema.number(
            "Seconds output has to stop for before the reply is complete "
            + "(default \(Defaults.settle), at most \(Defaults.maximumSettle)).")
        let timeout = ToolJSONSchema.number(
            "Seconds to wait at most; a command still printing then is reported as still running "
            + "(default \(Defaults.timeout), at most \(Defaults.maximumTimeout)).")
        return [
            ToolDefinition(
                name: ToolName.list,
                description: """
                The Terminal Chats open in this app: each one's id, project, directory, pane number \
                and whether it is connected to a terminal.
                """,
                parametersJSONSchema: ToolJSONSchema.object(properties: [:])
            ),
            ToolDefinition(
                name: ToolName.run,
                description: """
                Type a command into a Terminal Chat's terminal and press Return, as if the user typed \
                it, then return what the terminal printed until it went quiet, prompt included. It \
                shows in the chat's transcript. Some names in the output may be the terminal's \
                privacy words; use them as given.
                """,
                parametersJSONSchema: ToolJSONSchema.object(properties: [
                    "chat": chat,
                    "command": ToolJSONSchema.string("The command line to type."),
                    "settle": settle,
                    "timeout": timeout
                ], required: ["command"])
            ),
            ToolDefinition(
                name: ToolName.wait,
                description: "More output from a command that was still running when run returned.",
                parametersJSONSchema: ToolJSONSchema.object(properties: [
                    "chat": chat, "settle": settle, "timeout": timeout
                ])
            ),
            ToolDefinition(
                name: ToolName.interrupt,
                description: "Send Control-C to a Terminal Chat's terminal and return what it printed in response.",
                parametersJSONSchema: ToolJSONSchema.object(properties: ["chat": chat])
            ),
            ToolDefinition(
                name: ToolName.screen,
                description: "The last lines on a Terminal Chat's terminal screen, as they are now.",
                parametersJSONSchema: ToolJSONSchema.object(properties: [
                    "chat": chat,
                    "lines": ToolJSONSchema.integer("How many lines (default \(Defaults.lines)).")
                ])
            )
        ]
    }

    // MARK: - Calls

    private struct Arguments: Decodable {
        var chat: String?
        var command: String?
        var settle: Double?
        var timeout: Double?
        var lines: Int?
    }

    public func callTool(name: String, argumentsJSON: Data) async -> (content: String, isError: Bool) {
        let action: TerminalChatControl.Action
        switch name {
        case ToolName.list: action = .list
        case ToolName.run: action = .run
        case ToolName.wait: action = .wait
        case ToolName.interrupt: action = .interrupt
        case ToolName.screen: action = .screen
        default: return ("Unknown tool \(name).", true)
        }
        let arguments: Arguments
        if argumentsJSON.isEmpty {
            arguments = Arguments()
        } else {
            do {
                arguments = try JSONDecoder().decode(Arguments.self, from: argumentsJSON)
            } catch {
                return ("The arguments to \(name) are not valid: \(error.localizedDescription)", true)
            }
        }
        // `interrupt` takes no timing of its own: Control-C either works
        // quickly or not at all.
        let request = TerminalChatControl.Request(
            action: action, chat: arguments.chat, command: arguments.command,
            settle: action == .interrupt ? nil : arguments.settle,
            timeout: action == .interrupt ? nil : arguments.timeout,
            lines: arguments.lines)
        return await answer(request)
    }

    @MainActor
    private func answer(_ request: TerminalChatControl.Request) async -> (content: String, isError: Bool) {
        let entries = directory.chatEntries
        let chats = entries.map(\.chat)
        if request.action == .list {
            return (Self.encode(chats), false)
        }
        let chat: TerminalChatControl.Chat
        switch TerminalChatControl.resolve(request.chat, in: chats) {
        case .success(let found): chat = found
        case .failure(let error): return (error.message, true)
        }
        guard let session = entries.first(where: { $0.chat.id == chat.id })?.session, session.isConnected else {
            return ("Terminal Chat \(chat.id) is not connected to a terminal — use "
                    + "Connect to Terminal in its pane's Settings.", true)
        }
        let durations = Self.durations(for: request)

        switch request.action {
        case .run:
            guard let command = request.command, !command.isEmpty else {
                return ("run needs a command.", true)
            }
            return (await session.run(command, settle: durations.settle, timeout: durations.timeout), false)
        case .wait:
            return (await session.waitForOutput(settle: durations.settle, timeout: durations.timeout), false)
        case .interrupt:
            return (await session.interruptAndWait(settle: durations.settle, timeout: durations.timeout), false)
        case .screen:
            return (session.screen(lines: request.lines ?? TerminalChatControl.Defaults.lines) ?? "", false)
        case .list:
            return (Self.encode(chats), false)
        }
    }

    /// The request's settle and timeout, defaulted and clamped to
    /// `TerminalChatControl.Defaults`.
    static func durations(for request: TerminalChatControl.Request) -> (settle: Duration, timeout: Duration) {
        typealias Defaults = TerminalChatControl.Defaults
        return (
            settle: duration(request.settle, default: Defaults.settle, limit: Defaults.maximumSettle),
            timeout: duration(request.timeout, default: Defaults.timeout(for: request.action),
                              limit: Defaults.maximumTimeout)
        )
    }

    private static func duration(_ seconds: Double?, default fallback: Double, limit: Double) -> Duration {
        .milliseconds(Int(min(max(seconds ?? fallback, 0.1), limit) * 1000))
    }

    private static func encode(_ chats: [TerminalChatControl.Chat]) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(chats), let text = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return text
    }
}
