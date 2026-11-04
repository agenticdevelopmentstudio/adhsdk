import Combine
import Foundation
import AgenticToolkitCore

/// A Claude Code session as the session daemon last saw it: just what the
/// Stop detector reads.
public struct AdkdSessionActivity: Sendable, Equatable {
    public var sessionID: String
    public var directory: String
    /// The `TERM_SESSION_ID` the session's hooks ran under; empty when the
    /// terminal set none.
    public var termSessionID: String
    /// The raw hook event name of the main agent's turn state (`Stop`,
    /// `PreToolUse`, …).
    public var lastEventType: String
    /// When ``lastEventType`` was recorded; empty from a daemon that predates
    /// the field.
    public var turnStateAt: String

    public init(sessionID: String, directory: String, termSessionID: String = "", lastEventType: String,
                turnStateAt: String = "") {
        self.sessionID = sessionID
        self.directory = directory
        self.termSessionID = termSessionID
        self.lastEventType = lastEventType
        self.turnStateAt = turnStateAt
    }
}

/// Where ``AdkdStopEventDetector`` reads the daemon's sessions from.
public protocol AdkdSessionActivitySource: Sendable {
    /// Recently active sessions, or nil when the daemon could not be read.
    func recentSessions() async -> [AdkdSessionActivity]?
}

/// The daemon's `/sessions`, through the same service the Sessions window
/// reads (pointed at adkd in the Kitchen).
public struct DaemonSessionActivitySource: AdkdSessionActivitySource {

    private let service: any StenographerDaemonService
    private let sinceHours: Int

    public init(service: any StenographerDaemonService, sinceHours: Int = 1) {
        self.service = service
        self.sinceHours = sinceHours
    }

    public func recentSessions() async -> [AdkdSessionActivity]? {
        guard let dtos = await service.sessions(status: nil, project: nil, sinceHours: sinceHours,
                                                includeCounts: false) else { return nil }
        return dtos.map {
            AdkdSessionActivity(sessionID: $0.sessionId, directory: $0.cwd, termSessionID: $0.termSessionId,
                                lastEventType: $0.lastEventType, turnStateAt: $0.turnStateAt)
        }
    }
}

/// Calls a session idle when the Claude Code session running in its pane ends
/// a turn: the daemon's turn state for it moves into `Stop` (or `StopFailure`,
/// a turn ended by an API error).
///
/// Exact where the quiet-period detector guesses — Claude Code prints at its
/// idle prompt, so silence is a poor signal there — but only for Claude Code,
/// and only while the daemon is up. Polls every `interval` seconds.
///
/// A row belongs to the pane whose id is its `TERM_SESSION_ID`, which the
/// registry sets on every pane it opens. A row with none is never a partner
/// pane's, whatever its directory: it is a Claude Code run the partner did not
/// open (the owner's own pane in the same project, a `claude -p`), and taking
/// it would report a turn that is not this pane's and disarm the pane before
/// its own Stop. A daemon too old to record the id leaves idles to the
/// quiet-period fallback. A
/// turn end is a *change* of turn state — keyed on the state's own clock
/// (`turnStateAt`) when the daemon reports it, on the event name alone when it
/// does not — so the activity that follows a Stop without starting a turn (the
/// idle-prompt notification a minute later, a background subagent) is never a
/// second idle. The state found by the first poll after watching is the past,
/// not news. Exits come from the terminal, as for any detector.
///
/// A nested Claude Code run (`claude -p` from a Bash call, a skill or a hook)
/// inherits the pane's `TERM_SESSION_ID`, so its rows are the pane's too. Its
/// Stop is not the pane's idle: while any other session in the pane is mid-turn
/// (its last event one of ``midTurnEvents``), a Stop is the nested run's and is
/// recorded without being reported, so the outer turn's own Stop later is the
/// idle. A session that replaced an idle one (`/clear`) still reports its turns.
@MainActor
public final class AdkdStopEventDetector: PartnerSessionEventDetecting {

    public var onIdle: ((UUID) -> Void)?
    public var onExit: ((UUID) -> Void)?

    private let source: any AdkdSessionActivitySource
    private let scheduler: any TimerScheduling
    private let interval: TimeInterval
    private var watched: [UUID: Watch] = [:]
    private var pollTimer: AnyCancellable?
    private var polling = false

    private static let turnEndingEvents: Set<String> = [HookEventType.stop.rawValue,
                                                        HookEventType.stopFailure.rawValue]

    /// The events that leave a session in the middle of a turn.
    static let midTurnEvents: Set<String> = Set([
        HookEventType.userPromptSubmit, .preToolUse, .postToolUse, .postToolUseFailure, .permissionRequest,
        .permissionDenied, .subagentStart, .subagentStop, .preCompact, .postCompact
    ].map(\.rawValue))

    private final class Watch {
        let paneID: String
        /// The last turn state seen for each Claude session in the pane. Nil
        /// until the first poll after watching has taken its baseline.
        var turnStates: [String: String]?
        var exitSubscription: AnyCancellable?

        init(paneID: String) {
            self.paneID = paneID
        }

        func owns(_ row: AdkdSessionActivity) -> Bool {
            row.termSessionID == paneID
        }
    }

    public init(source: any AdkdSessionActivitySource, interval: TimeInterval = 5,
                scheduler: any TimerScheduling = DispatchTimerScheduler()) {
        self.source = source
        self.interval = interval
        self.scheduler = scheduler
    }

    public func watch(_ session: PartnerSession) {
        unwatch(id: session.id)
        let id = session.id
        let watch = Watch(paneID: id.uuidString)
        watch.exitSubscription = session.terminal.onTermination { [weak self] in self?.exited(id: id) }
        watched[id] = watch
        schedulePoll()
    }

    public func unwatch(id: UUID) {
        guard let watch = watched.removeValue(forKey: id) else { return }
        watch.exitSubscription?.cancel()
        if watched.isEmpty { pollTimer = nil }
    }

    /// Reads the daemon once and reports every pane whose agent ended a turn.
    /// The timer calls it; so can a test.
    public func poll() async {
        guard !polling, !watched.isEmpty else { return }
        polling = true
        defer { polling = false }
        guard let rows = await source.recentSessions() else { return }
        for (id, watch) in watched {
            let isBaseline = watch.turnStates == nil
            var states = watch.turnStates ?? [:]
            var endedTurn = false
            let owned = rows.filter(watch.owns)
            for row in owned {
                let state = row.turnStateAt.isEmpty ? row.lastEventType : "\(row.lastEventType)@\(row.turnStateAt)"
                let insideAnotherTurn = owned.contains {
                    $0.sessionID != row.sessionID && Self.midTurnEvents.contains($0.lastEventType)
                }
                if !isBaseline, states[row.sessionID] != state, !insideAnotherTurn,
                   Self.turnEndingEvents.contains(row.lastEventType) {
                    endedTurn = true
                }
                states[row.sessionID] = state
            }
            watch.turnStates = states
            if endedTurn { onIdle?(id) }
        }
    }

    private func schedulePoll() {
        guard pollTimer == nil, !watched.isEmpty else { return }
        pollTimer = scheduler.schedule(after: interval) { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                await self.poll()
                self.pollTimer = nil
                self.schedulePoll()
            }
        }
    }

    private func exited(id: UUID) {
        guard watched[id] != nil else { return }
        onExit?(id)
    }
}
