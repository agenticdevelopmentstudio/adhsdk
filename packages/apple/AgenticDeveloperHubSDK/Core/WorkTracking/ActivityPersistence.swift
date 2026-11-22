import Foundation

/// Where work-tracking writes. The host implements it over its own database.
/// Every timestamp is ISO-8601 UTC (`UTCTimestamp`).
public protocol ActivityPersistence: AnyObject, Sendable {
    func openActivitySpan(_ span: ActivitySpanDTO) throws
    /// Ends the span if it is still open; a closed span keeps its first end.
    /// A span shorter than one second is deleted instead. Opening an id that
    /// already exists throws.
    func closeActivitySpan(id: String, endedAt: String) throws
    func retitleActivitySpan(id: String, title: String) throws
    /// Heartbeat: the span was still current at `at`.
    func touchActivitySpan(id: String, at: String) throws // swiftlint:disable:this identifier_name
    /// Opens an idle interval unless one is already open.
    func openIdleInterval(from: String) throws
    /// Closes the open idle interval, if any.
    func closeIdleInterval(until: String) throws
    /// After a restart: every open span closed per `ActivityRecovery`, every
    /// open idle interval closed at `now`. Returns the spans that survived
    /// closing — one deleted for being under a second is not counted.
    @discardableResult func recoverActivity(now: String) throws -> Int
    /// Deletes derived spans that ended before `before`, and idle intervals
    /// that ended before it. What "derived" means is the host's. Returns rows deleted.
    @discardableResult func pruneActivity(endedBefore before: String) throws -> Int
    func activitySpans(since: String, limit: Int) throws -> [ActivitySpanDTO]   // newest first
    func openActivitySpans() throws -> [ActivitySpanDTO]
}

/// What closing one span did.
public enum ActivitySpanClose: Sendable, Equatable {
    /// No open span had that id.
    case none
    /// The span ended.
    case closed
    /// The span was under a second long and is gone.
    case deleted
}

public enum ActivityRecovery {
    /// Where a span left open by a crash ends: its last heartbeat (or its
    /// start without one), pulled back to the start of an idle interval that
    /// opened after that heartbeat and is still open. Never later than the
    /// heartbeat — downtime is never billed.
    public static func recoveredEnd(startedAt: String, lastSeenAt: String, openIdleFrom: [String]) -> String {
        let start = UTCTimestamp.canonical(startedAt) ?? startedAt
        let seen = lastSeenAt.isEmpty ? "" : (UTCTimestamp.canonical(lastSeenAt) ?? lastSeenAt)
        let base = seen.isEmpty ? start : seen
        let idle = openIdleFrom
            .map { UTCTimestamp.canonical($0) ?? $0 }
            .filter { $0 >= start && $0 <= base }
            .min()
        return idle ?? base
    }
}

/// The storage a `WorkTrackingController` runs against: the activity tables,
/// the work-tracking settings, and the repo roots the host already knows.
/// The host conforms its database; every rule stays in the controller (review F14).
/// Declared in Core, beside ``ActivityPersistence``, so the session database
/// (a tier below Activity) can conform to it.
public protocol WorkTrackingPersistence: ActivityPersistence, WorkTrackingSettingsStore {
    /// Project roots the host knows from its own records, for the title
    /// fallback: roots it bills, and roots of sessions active at or after
    /// `cutoff` (ISO-8601 UTC). Blank roots are left out; order is free.
    func knownRepoRoots(activeSince cutoff: String) throws -> [String]
}
