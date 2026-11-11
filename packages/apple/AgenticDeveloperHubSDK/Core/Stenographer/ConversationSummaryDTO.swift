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

    /// The branches a checkout sits on when nothing is in progress. `HEAD` is
    /// what a detached checkout reports.
    public static let baseBranches: Set<String> = ["", "main", "master", "HEAD"]

    /// Whether the conversation is work in progress: its session is on a
    /// feature branch (anything but ``baseBranches``) or runs inside a
    /// worktree (a `.claude/worktrees/<name>` directory, at any depth).
    public static func isWorkInProgress(session: SessionDTO) -> Bool {
        !baseBranches.contains(session.gitBranch) || isInWorktree(session.cwd)
    }

    /// Whether `path` is inside a `.claude/worktrees/<name>` worktree.
    public static func isInWorktree(_ path: String) -> Bool {
        let segments = path.split(separator: "/")
        return segments.indices.contains { index in
            segments[index] == ".claude" && index + 2 < segments.count && segments[index + 1] == "worktrees"
        }
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
    /// Whether `steno conversation send` may type into this session's pane
    /// (``ConversationSendability``).
    public let canSend: Bool
    /// Why it may not ("" when ``canSend``).
    public let sendRefusal: String

    /// - Parameter liveSessions: the active sessions, which ``canSend`` checks for
    ///   one sharing this session's pane.
    public init(session: SessionDTO, liveSessions: [SessionDTO], homeDirectory: String = NSHomeDirectory()) {
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
        let refusal = ConversationSendability.refusal(for: session, liveSessions: liveSessions)
        canSend = refusal == nil
        sendRefusal = refusal ?? ""
    }
}

/// Whether a message may be typed into a conversation's terminal pane — the one
/// answer `steno conversation send` acts on and `info`'s `canSend` reports.
public enum ConversationSendability {
    /// Why a message must not be typed into `session`'s pane, or nil when it may.
    ///
    /// A session ``ConversationStatus/waiting`` on the person is refused, not just an
    /// ended one: its pane holds a permission or question prompt, which ignores the
    /// typed letters and takes the Return that follows as picking its highlighted
    /// choice — approving a tool nobody approved.
    ///
    /// So is a session whose pane another of `liveSessions` resolves to as well. A
    /// headless or nested `claude` (`claude -p` from another session's Bash tool, an
    /// agent runner) inherits its parent's `TERM_SESSION_ID` and TTY, so the pane its
    /// record names is the parent's: text meant for the child would be typed into the
    /// parent, which would act on it. Nothing recorded tells the two apart, so neither
    /// is sent to while both are live.
    public static func refusal(for session: SessionDTO, liveSessions: [SessionDTO]) -> String? {
        let id = session.sessionId
        switch ConversationStatus(session: session) {
        case .ended:
            return "conversation \(id) has ended."
        case .waiting:
            return "conversation \(id) is waiting on a prompt (a permission or a question); answer it in "
                + "its terminal. A message typed now would land in the prompt, and its Return would pick "
                + "the highlighted choice."
        case .busy, .idle:
            break
        }
        guard TerminalTextInjector.isSupported(termProgram: session.termProgram) else {
            let term = session.termProgram.isEmpty ? "an unknown terminal" : session.termProgram
            return "typing into a conversation needs iTerm2 or Terminal.app; \(id) runs in \(term)."
        }
        if let sharer = paneSharer(of: session, among: liveSessions) {
            return "conversation \(sharer.sessionId) runs in the same terminal pane as \(id) (a nested or "
                + "headless claude shares its parent's), so a message can't be aimed at \(id) alone."
        }
        return nil
    }

    /// Another active session whose pane resolves to the same target as `session`'s.
    private static func paneSharer(of session: SessionDTO, among liveSessions: [SessionDTO]) -> SessionDTO? {
        guard let pane = pane(of: session) else { return nil }
        return liveSessions.first {
            $0.sessionId != session.sessionId && $0.status == SessionStatus.active.rawValue && self.pane(of: $0) == pane
        }
    }

    private static func pane(of session: SessionDTO) -> TerminalTextInjector.Target? {
        TerminalTextInjector.resolveTarget(
            termProgram: session.termProgram, termSessionId: session.termSessionId, pid: session.pid)
    }
}
