#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation
import os

/// Replays the raw archive's older records into the live `events.db`, a slice
/// at a time, after a cutover started the daemon on a partly replayed one
/// (`scripts/legacy_split.py cutover` sets `replay_target_raw_id`).
///
/// The daemon runs normally the whole time: the slice is a live replay
/// (`ClaudeArchiveReplay.backfill`, no bulk load, small chunks, each committing
/// its cursor), so the drain keeps writing new captures beside it, and a stop
/// at any point resumes from the last committed chunk on the next slice.
///
/// **Off the cooperative pool.** A slice is minutes of synchronous SQLite, so
/// it runs on its own serial queue, like a trim pass.
public final class HistoryBackfill: Sendable {
    /// How long one slice runs before it stops and lets the trim go.
    static let sliceSeconds: TimeInterval = 600

    /// What one slice did.
    enum SliceOutcome: Sendable, Equatable {
        /// The Claude pipeline is not open.
        case unavailable
        /// No backfill is pending.
        case idle
        /// A slice is already running.
        case busy
        /// The slice ran out of time; records remain.
        case progressed(lastRawID: Int64)
        /// The cursor reached the target.
        case finished(lastRawID: Int64)
        /// The slice stopped on an error; what it committed stays.
        case failed(String)
    }

    private static let queue = DispatchQueue(label: "SessionDaemon.HistoryBackfill", qos: .utility)

    private struct State {
        var running = false
        var lastError: String?
    }

    private let state = OSAllocatedUnfairLock(initialState: State())
    private let claude: ClaudePipelineSlot
    private let now: @Sendable () -> Date

    init(claude: ClaudePipelineSlot, now: @escaping @Sendable () -> Date = Date.init) {
        self.claude = claude
        self.now = now
    }

    public var isRunning: Bool { state.withLock { $0.running } }

    /// The backfill as `/storage` reports it: nil when the pipeline is not
    /// open, the status cannot be read, or no backfill is pending.
    public func status() -> HistoryBackfillDTO? {
        guard let store = claude.current?.store,
              let status = try? ClaudeArchiveReplay.backfillStatus(in: store),
              status.pending, let target = status.target else { return nil }
        let snapshot = state.withLock { $0 }
        return HistoryBackfillDTO(
            targetRawID: target, lastRawID: status.lastRawID, running: snapshot.running,
            lastError: snapshot.lastError)
    }

    /// Whether a backfill is pending in `pipeline`'s store; a status that
    /// cannot be read counts as pending (the reaper must stay off).
    static func pending(in pipeline: ClaudePipelineHandles) -> Bool {
        do {
            return try ClaudeArchiveReplay.backfillStatus(in: pipeline.store).pending
        } catch {
            logger.error("Could not read the history backfill: \(error.localizedDescription, privacy: .public)")
            return true
        }
    }

    /// What a trim pass reports while ``trimHold(in:)`` holds it back.
    static let waitingForBackfill = "history backfill"

    /// Days the hold keeps before the frontier's received day: a transcript
    /// line can be stamped a day before it was received, and the trim's own
    /// cutoff is the start of the day after the hold.
    static let frontierMarginDays = 2

    /// The last day a trim may reach while a backfill is pending: two days
    /// before the day the next unreplayed archive record was received. The
    /// backfill delivers a day's events over several slices, with a trim after
    /// each; a trim that reached a day the backfill has not finished would fold
    /// its first turns into `trimmed_turns` and delete its events, and the late
    /// turns that followed would find a usage summary they can only replace,
    /// never add to. Holding the trim behind the frontier lets every day arrive
    /// whole before it can be trimmed.
    ///
    /// Nil when no backfill is pending, or nothing is left before its target.
    /// A status or record that cannot be read fails closed: a hold on
    /// 1970-01-01, which deletes nothing (a throw would read "billing
    /// unreadable").
    ///
    /// The archive's ids are in received order except where a later import
    /// added older records; a frontier that steps back to such a block finds
    /// the days before it possibly trimmed already. Duplicates of trimmed turns
    /// are dropped by `trimmed_turn_keys`, and a later observation of one moves
    /// only its difference into `trimmed_turns`; a new line there misses the
    /// summaries, and its bytes stay in `claude-raw.db`.
    static func trimHold(in pipeline: ClaudePipelineHandles?) -> TrimHold? {
        guard let pipeline else { return nil }
        do {
            let status = try ClaudeArchiveReplay.backfillStatus(in: pipeline.store)
            guard status.pending, let target = status.target,
                  let next = try pipeline.archive.records(after: status.lastRawID, limit: 1).first,
                  next.id <= target else { return nil }
            return TrimHold(day: holdDay(frontier: next.record.receivedAt), reason: waitingForBackfill)
        } catch {
            logger.error(
                "Could not read the history backfill's frontier: \(error.localizedDescription, privacy: .public)")
            return TrimHold(day: "1970-01-01", reason: waitingForBackfill)
        }
    }

    /// The hold day for a frontier record received at `frontier`.
    static func holdDay(frontier: Date) -> String {
        UTCDay.string(from: frontier.addingTimeInterval(-Double(frontierMarginDays) * 86_400))
    }

    /// Runs one slice of at most `seconds`, unless one is running.
    func runSlice(seconds: TimeInterval = sliceSeconds) async -> SliceOutcome {
        guard let pipeline = claude.current else { return .unavailable }
        guard Self.pending(in: pipeline) else { return .idle }
        let claimed = state.withLock { state -> Bool in
            if state.running { return false }
            state.running = true
            return true
        }
        guard claimed else { return .busy }
        let deadline = now().addingTimeInterval(seconds)
        let now = self.now
        let outcome = await withCheckedContinuation { (continuation: CheckedContinuation<SliceOutcome, Never>) in
            Self.queue.async {
                continuation.resume(returning: Self.slice(pipeline, shouldContinue: { now() < deadline }))
            }
        }
        state.withLock { state in
            state.running = false
            if case .failed(let error) = outcome { state.lastError = error } else { state.lastError = nil }
        }
        return outcome
    }

    /// One slice, synchronously: the backfill until `shouldContinue` refuses
    /// or the target is reached.
    static func slice(_ pipeline: ClaudePipelineHandles, shouldContinue: @escaping @Sendable () -> Bool)
        -> SliceOutcome {
        do {
            let result = try ClaudeArchiveReplay.backfill(
                archive: pipeline.archive, store: pipeline.store, shouldContinue: shouldContinue)
            logger.info("""
                History backfill slice: \(result.replayed) replayed, \(result.failedThisRun) failed, \
                last raw id \(result.lastRawID), \(result.interrupted ? "more to go" : "done")
                """)
            return result.interrupted
                ? .progressed(lastRawID: result.lastRawID) : .finished(lastRawID: result.lastRawID)
        } catch let stopped as ClaudeArchiveReplayStopped {
            logger.error("""
                History backfill slice stopped at raw id \(stopped.partial.lastRawID): \
                \(stopped.cause, privacy: .public)
                """)
            return .failed(stopped.cause)
        } catch {
            logger.error("History backfill slice failed: \(error.localizedDescription, privacy: .public)")
            return .failed(error.localizedDescription)
        }
    }
}

extension HistoryBackfill: Loggable {
    public static nonisolated let logger = makeLogger()
}
#endif
