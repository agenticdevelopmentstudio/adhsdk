import Foundation

/// How something outside a Terminal Chat — Claude Code, through the MCP
/// tools an app serves (`TerminalChatDirectoryToolSource`) — drives the app's
/// Terminal Chats: lists them, types a command into one, and gets back what
/// the terminal printed, concealed by that chat's substitutions exactly as its
/// own transcript shows it.
///
/// This is the protocol's vocabulary — the actions, the request and reply
/// shapes, the defaults and limits, and how a chat id prefix resolves —
/// independent of any transport.
public enum TerminalChatControl {

    public enum Action: String, Codable, Sendable {
        /// The chats this app hosts.
        case list
        /// Type `command` into the chat and return the reply.
        case run
        /// More output from a command that outlasted `run`.
        case wait
        /// Control-C, and what the terminal printed in response.
        case interrupt
        /// The last `lines` lines on the terminal's screen.
        case screen
    }

    /// What a request that leaves a field out gets, and the most it may ask
    /// for — the one statement of them, read by the session's own defaults,
    /// the app's tools and their descriptions.
    public enum Defaults {
        /// Seconds output has to stop for before a reply is complete.
        public static let settle: Double = 1.5
        /// Seconds a `run` or `wait` waits at most.
        public static let timeout: Double = 60
        /// Seconds an `interrupt` waits at most: Control-C either works
        /// quickly or not at all.
        public static let interruptTimeout: Double = 10
        /// Lines `screen` returns.
        public static let lines = 40
        public static let maximumSettle: Double = 60
        public static let maximumTimeout: Double = 600

        /// The timeout `action` gets when the request names none.
        public static func timeout(for action: Action) -> Double {
            action == .interrupt ? interruptTimeout : timeout
        }
    }

    public struct Request: Codable, Sendable, Equatable {
        public var action: Action
        /// A chat's id, or a prefix of one. Optional when the app hosts
        /// exactly one chat.
        public var chat: String?
        public var command: String?
        /// Seconds output has to stop for before the reply is complete.
        public var settle: Double?
        /// Seconds to wait at most; a command still printing then is
        /// reported as still running.
        public var timeout: Double?
        public var lines: Int?

        public init(action: Action, chat: String? = nil, command: String? = nil,
                    settle: Double? = nil, timeout: Double? = nil, lines: Int? = nil) {
            self.action = action
            self.chat = chat
            self.command = command
            self.settle = settle
            self.timeout = timeout
            self.lines = lines
        }
    }

    public struct Chat: Codable, Sendable, Equatable {
        public var id: String
        public var project: String
        public var directory: String
        /// The pane's number in its project window, as the window shows it.
        public var paneNumber: Int
        /// Whether the chat has a terminal to type into.
        public var connected: Bool

        public init(id: String, project: String, directory: String, paneNumber: Int, connected: Bool) {
            self.id = id
            self.project = project
            self.directory = directory
            self.paneNumber = paneNumber
            self.connected = connected
        }
    }

    public struct Response: Codable, Sendable, Equatable {
        public var error: String?
        /// The app answering, for a client talking to several.
        public var app: String?
        public var chats: [Chat]?
        /// The chat that answered a run, wait, interrupt or screen.
        public var chat: String?
        public var output: String?

        public var isSuccess: Bool { error == nil }

        public init(error: String? = nil, app: String? = nil, chats: [Chat]? = nil,
                    chat: String? = nil, output: String? = nil) {
            self.error = error
            self.app = app
            self.chats = chats
            self.chat = chat
            self.output = output
        }

        public static func failure(_ message: String) -> Response { Response(error: message) }
    }

    /// Picks the chat a request means: the one whose id starts with `query`,
    /// or the only one when `query` is nil. Answers an error message instead
    /// when that is none or more than one.
    public static func resolve(_ query: String?, in chats: [Chat]) -> Result<Chat, ResolveError> {
        let query = query?.lowercased()
        let matches = query.map { prefix in chats.filter { $0.id.lowercased().hasPrefix(prefix) } } ?? chats
        switch matches.count {
        case 1: return .success(matches[0])
        case 0: return .failure(ResolveError(message: query.map { "No Terminal Chat with id \($0)." }
                                             ?? "There is no Terminal Chat open."))
        default:
            let ids = matches.map(\.id).joined(separator: ", ")
            return .failure(ResolveError(message: "More than one Terminal Chat matches — choose one of: \(ids)"))
        }
    }

    public struct ResolveError: Error, Equatable {
        public let message: String
    }
}
