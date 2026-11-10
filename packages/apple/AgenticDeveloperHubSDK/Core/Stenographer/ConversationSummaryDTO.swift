import Foundation

/// A conversation: a live terminal session in which a person is talking to an
/// agent. Built from the daemon's ``SessionDTO`` — the session *is* the
/// conversation; these types only say it the way a conversation reader asks.
///
/// Every session the daemon records is a Claude Code session, because Claude
/// Code's hooks are what record it, so every conversation's agent is Claude —
/// stated as a field rather than assumed, so a second agent is a new value and
/// not a new shape.
public enum ConversationAgent {
    public static let claude = "claude"
}

/// What a conversation is doing, as a reader deciding whether to send asks it.
public enum ConversationStatus: String, Codable, Sendable, CaseIterable {
    /// The agent is mid-turn (or a subagent is): a message sent now queues.
    case busy
    /// Alive, with nothing in flight: the agent is at its prompt.
    case idle
    /// The agent is blocked on the person — a permission prompt, a question.
    case waiting
    /// The session's process is gone.
    case ended

    /// ``SessionActivity``'s reading of the session, in a conversation's words.
    public init(session: SessionDTO) {
        guard session.status == SessionStatus.active.rawValue else {
            self = .ended
            return
        }
        switch SessionActivity.derive(
            isActive: true, lastEventType: session.lastEventType, subagentWorking: session.subagentWorking
        ) {
        case .working: self = .busy
        case .idle: self = .idle
        case .waiting: self = .waiting
        }
    }
}

/// One row of `steno conversations list`: what a reader needs to pick a
/// conversation and address it with `steno conversation`.
public struct ConversationSummaryDTO: Codable, Sendable, Equatable {
    /// The session id — the id every `steno conversation` verb takes.
    public let id: String
    /// The agent on the other side (``ConversationAgent``).
    public let agent: String
    /// The terminal it runs in, by name ("iTerm2"), else its `TERM_PROGRAM`.
    public let terminal: String
    /// The session's working directory, `~`-relative when it is under home.
    public let cwd: String
    /// The session's name (`/rename`, or Claude's own title); "" when unnamed.
    public let sessionName: String
    public let gitBranch: String
    /// When the session last did anything, as an ISO-8601 UTC instant.
    public let lastActivity: String
    public let status: ConversationStatus

    public init(session: SessionDTO, homeDirectory: String = NSHomeDirectory()) {
        id = session.sessionId
        agent = ConversationAgent.claude
        terminal = Self.terminalName(session.termProgram)
        cwd = Self.homeRelative(session.cwd, homeDirectory: homeDirectory)
        sessionName = session.transcriptTitle
        gitBranch = session.gitBranch
        lastActivity = UTCTimestamp.canonical(session.lastActivityAt) ?? session.lastActivityAt
        status = ConversationStatus(session: session)
    }

    /// Whether `app` names this conversation's agent or its terminal — by
    /// `TERM_PROGRAM` or by name, ignoring case, a prefix being enough
    /// (`iterm` names iTerm2, `terminal` names Terminal.app).
    public static func matches(app: String, session: SessionDTO) -> Bool {
        let wanted = app.lowercased()
        guard !wanted.isEmpty else { return true }
        var names = [ConversationAgent.claude, session.termProgram]
        if let known = KnownTerminals.match(termProgram: session.termProgram) { names.append(known.displayName) }
        return names.contains { !$0.isEmpty && $0.lowercased().hasPrefix(wanted) }
    }

    /// A `TERM_PROGRAM` as the terminal's name, or the raw value when unknown.
    public static func terminalName(_ termProgram: String) -> String {
        KnownTerminals.match(termProgram: termProgram)?.displayName ?? termProgram
    }

    /// `path` with the home directory written `~`.
    public static func homeRelative(_ path: String, homeDirectory: String) -> String {
        let home = homeDirectory.hasSuffix("/") ? String(homeDirectory.dropLast()) : homeDirectory
        guard !home.isEmpty else { return path }
        if path == home { return "~" }
        if path.hasPrefix(home + "/") { return "~" + path.dropFirst(home.count) }
        return path
    }
}

/// `steno conversation info`: the summary, and the rest of what the daemon
/// knows about the session.
public struct ConversationInfoDTO: Codable, Sendable, Equatable {
    public let id: String
    public let agent: String
    public let terminal: String
    /// The raw `TERM_PROGRAM` ("" when unknown).
    public let termProgram: String
    public let cwd: String
    /// The top-level git project root, `~`-relative ("" until resolved).
    public let projectRoot: String
    public let sessionName: String
    public let gitBranch: String
    public let model: String
    /// ISO-8601 UTC instants.
    public let startedAt: String
    public let lastActivity: String
    public let status: ConversationStatus
    /// The last hook event of the main agent's turn, which ``status`` reads.
    public let lastEvent: String
    public let lastTool: String
    /// The summarizer's line about what the session is doing ("" when none).
    public let summary: String
    public let pid: Int
    /// Whether `steno conversation send` can type into this session's pane:
    /// alive, and in a terminal the sender can target exactly.
    public let canSend: Bool

    public init(session: SessionDTO, homeDirectory: String = NSHomeDirectory()) {
        let summary = ConversationSummaryDTO(session: session, homeDirectory: homeDirectory)
        id = summary.id
        agent = summary.agent
        terminal = summary.terminal
        termProgram = session.termProgram
        cwd = summary.cwd
        projectRoot = ConversationSummaryDTO.homeRelative(session.projectRoot, homeDirectory: homeDirectory)
        sessionName = summary.sessionName
        gitBranch = summary.gitBranch
        model = session.model
        startedAt = UTCTimestamp.canonical(session.startedAt) ?? session.startedAt
        lastActivity = summary.lastActivity
        status = summary.status
        lastEvent = session.lastEventType
        lastTool = session.lastTool
        self.summary = session.summary
        pid = session.pid
        canSend = summary.status != .ended && TerminalTextInjector.isSupported(termProgram: session.termProgram)
    }
}
