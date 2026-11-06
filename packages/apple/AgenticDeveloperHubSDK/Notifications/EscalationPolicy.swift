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

    /// The urgency to present at, once the notice's age (from its timestamp)
    /// reaches the threshold; nil before that, or when the step is off.
    public func escalated(_ notice: Notice, now: Date) -> Notice.Urgency? {
        guard let step = step(for: notice),
              now.timeIntervalSince(notice.timestamp) >= step.after else { return nil }
        return step.to
    }

    /// When `escalated` will first answer non-nil, or nil if it never will.
    public func nextCheck(for notice: Notice) -> Date? {
        step(for: notice).map { notice.timestamp.addingTimeInterval($0.after) }
    }
}
