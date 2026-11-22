#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import OSLog
import Foundation

/// Notices when the user interrupts a session's turn and records it as
/// `HookEventType.interruptedEventType`, so the Sessions window stops showing it as working.
///
/// Claude Code fires no hook for an interrupt. The session's recorded state stays
/// whatever the cut-short turn last did — usually a `PreToolUse` — and reads as
/// working until the user next types something, which may be never. The one trace
/// an interrupt leaves is in the transcript: a user record reading
/// `[Request interrupted by user…]` (see `SessionEnricher.transcriptInterruptTimestamp`).
///
/// Every tick reads the tail of each in-flight session's transcript. The write is a
/// compare-and-set on the state it read, so a hook that lands in between wins, and it
/// only takes an interrupt newer than that state — the transcript lags the hooks, so
/// an old interrupt can still be its newest record when the next prompt's hook lands.
///
/// Separate from ``LivenessTask``: that one decides whether a session exists at all,
/// from processes; this one what its turn is doing, from transcripts.
public struct InterruptedTurnTask: SessionDaemonTask {
    public let name = "interrupted-turn"
    public let schedule: SessionTaskSchedule
    let database: DaemonDatabase
    /// Resolves a session's transcript when the hooks recorded none. Injected so tests
    /// don't scan the real `~/.claude/projects`.
    let findTranscriptPath: @Sendable (String) -> String?

    public init(
        database: DaemonDatabase,
        checkInterval: TimeInterval = 5,
        findTranscriptPath: @escaping @Sendable (String) -> String? = SessionEnricher.findTranscriptPath
    ) {
        self.database = database
        self.findTranscriptPath = findTranscriptPath
        self.schedule = SessionTaskSchedule(
            intervalSeconds: checkInterval,
            enabled: true,
            timeout: 30,
            backoffOnFailure: false
        )
    }

    public func execute(context: SessionTaskContext) async throws -> SessionTaskResult {
        _ = try markInterruptedTurns()
        return .empty
    }

    /// Records every in-flight session whose transcript ends in an interrupt, and
    /// returns their ids.
    func markInterruptedTurns() throws -> [String] {
        var marked: [String] = []
        for candidate in try database.turnStateCandidates() {
            let recorded = candidate.transcriptPath.isEmpty ? nil : candidate.transcriptPath
            guard let path = recorded ?? findTranscriptPath(candidate.sessionId),
                  let interruptedAt = SessionEnricher.transcriptInterruptTimestamp(path: path) else { continue }
            let changed = try database.markTurnInterrupted(
                sessionId: candidate.sessionId,
                ifEventType: candidate.lastEventType,
                setAt: candidate.turnStateAt,
                interruptedAt: interruptedAt
            )
            if changed {
                logger.info("Session \(candidate.sessionId, privacy: .public) turn was interrupted")
                marked.append(candidate.sessionId)
            }
        }
        return marked
    }
}

extension InterruptedTurnTask: Loggable {
    public static nonisolated let logger = makeLogger()
}
#endif
