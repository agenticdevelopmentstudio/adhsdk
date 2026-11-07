import Foundation

/// When an untouched notice is re-presented as more urgent. Presentation-only:
/// the stored urgency never changes. A threshold of 0 turns that step off.
public struct EscalationPolicy: Codable, Sendable, Equatable {

    public var soonToNowAfter: TimeInterval
    public var eventuallyToSoonAfter: TimeInterval

    public init(soonToNowAfter: TimeInterval = 900, eventuallyToSoonAfter: TimeInterval = 0) {
        self.soonToNowAfter = soonToNowAfter
        self.eventuallyToSoonAfter = eventuallyToSoonAfter
    }

    private func step(for notice: Notice) -> (after: TimeInterval, to: Notice.Urgency)? {
        switch notice.urgency {
        case .soon where soonToNowAfter > 0: (soonToNowAfter, .now)
        case .eventually where eventuallyToSoonAfter > 0: (eventuallyToSoonAfter, .soon)
        default: nil
        }
    }

    /// Where the escalation clock starts: the notice's timestamp, or `since`
    /// (when it went on screen) if that is later. A backlog notice drawn an
    /// hour after it was posted gets its full threshold on screen.
    private static func start(of notice: Notice, since: Date?) -> Date {
        guard let since else { return notice.timestamp }
        return max(notice.timestamp, since)
    }

    /// The urgency to present at, once the notice has been waiting the
    /// threshold (counted from `since` when later than its timestamp); nil
    /// before that, or when the step is off.
    public func escalated(_ notice: Notice, since: Date? = nil, now: Date) -> Notice.Urgency? {
        guard let step = step(for: notice),
              now.timeIntervalSince(Self.start(of: notice, since: since)) >= step.after else { return nil }
        return step.to
    }

    /// When `escalated` will first answer non-nil, or nil if it never will.
    public func nextCheck(for notice: Notice, since: Date? = nil) -> Date? {
        step(for: notice).map { Self.start(of: notice, since: since).addingTimeInterval($0.after) }
    }
}
