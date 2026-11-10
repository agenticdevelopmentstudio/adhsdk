#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation

/// Where a daemon's Claude pipeline lives once it is open: empty while its files
/// could not be opened, filled once (at startup, or by a later retry), never
/// emptied. Every consumer reads it at call time, so a pipeline that opens
/// mid-run reaches the capture path, the drop-directory wake, the transcript
/// sweep, the import route and the quarantine routes without being rebuilt.
///
/// It also carries the open-retry step, so a caller that logs "not open" can
/// log it once per step (``shouldReportUnavailable()``) rather than on every wake.
public final class ClaudePipelineSlot: @unchecked Sendable {

    /// What `/health` reports as `claude_pipeline`.
    public enum State: String, Sendable {
        case open
        case unavailable
    }

    private let lock = NSLock()
    private var handles: ClaudePipelineHandles?
    /// Failed open attempts so far; one "not open" report is allowed per value.
    private var failedOpens = 0
    private var reportedAtStep = -1

    public init(_ handles: ClaudePipelineHandles? = nil) {
        self.handles = handles
    }

    /// The pipeline, or nil while it is not open.
    public var current: ClaudePipelineHandles? { lock.withLock { handles } }

    public var state: State { current == nil ? .unavailable : .open }

    /// Fills the slot. Returns false (and changes nothing) when it is already full:
    /// a pipeline is attached once per run.
    @discardableResult
    public func fill(_ pipeline: ClaudePipelineHandles) -> Bool {
        lock.withLock {
            guard handles == nil else { return false }
            handles = pipeline
            return true
        }
    }

    /// Runs `open` with the pipeline when it is there; otherwise runs `held` while
    /// holding the slot's lock, so a fill cannot land between "it is not open"
    /// and the `held` write. That is what lets a filler adopt everything `held`
    /// wrote: a fill that follows has seen it, and a capture that follows the
    /// fill takes `open`.
    public func route<Result>(
        open: (ClaudePipelineHandles) throws -> Result,
        held: () throws -> Result
    ) rethrows -> Result {
        lock.lock()
        if let handles {
            lock.unlock()
            return try open(handles)
        }
        defer { lock.unlock() }
        return try held()
    }

    /// Runs `body` while holding the slot's lock with the slot still empty, then
    /// fills it. `body` is where a filler moves what `route`'s `held` wrote; a
    /// throw leaves the slot empty. Returns false when the slot was already full.
    @discardableResult
    public func fill(_ pipeline: ClaudePipelineHandles, adopting body: () throws -> Void) rethrows -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard handles == nil else { return false }
        try body()
        handles = pipeline
        return true
    }

    /// Records one failed open attempt; the next ``shouldReportUnavailable()``
    /// says yes again.
    public func recordFailedOpen() {
        lock.withLock { failedOpens += 1 }
    }

    /// True once per failed-open step: a caller logs "not open" only when this
    /// says so, which throttles the log to the retry's backoff.
    public func shouldReportUnavailable() -> Bool {
        lock.withLock {
            guard handles == nil, reportedAtStep != failedOpens else { return false }
            reportedAtStep = failedOpens
            return true
        }
    }
}

/// The routes reach the pipeline quarantine through the slot: with nothing open
/// there is nothing quarantined, nothing to requeue and nothing to clear.
extension ClaudePipelineSlot: PipelineQuarantineControl {
    public func quarantinedCount() -> Int { current?.quarantinedCount() ?? 0 }

    @discardableResult
    public func requeueAllQuarantined() -> Int { current?.requeueAllQuarantined() ?? 0 }

    @discardableResult
    public func clearArchivedQuarantine() -> Int { current?.clearArchivedQuarantine() ?? 0 }
}
#endif
