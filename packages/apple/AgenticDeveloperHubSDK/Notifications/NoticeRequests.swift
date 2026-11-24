import Foundation

/// Body of a snooze request. `until` is an absolute time, `minutes` a duration
/// from now; `until` wins when both are present.
public struct SnoozeRequest: Codable, Sendable, Equatable {
    public var until: Date?
    public var minutes: Double?

    public init(until: Date? = nil, minutes: Double? = nil) {
        self.until = until
        self.minutes = minutes
    }

    /// The wake-up time, or nil when the request names none or asks for a
    /// non-positive duration.
    public func resolvedUntil(now: Date) -> Date? {
        if let until { return until }
        guard let minutes, minutes > 0 else { return nil }
        return now.addingTimeInterval(minutes * 60)
    }
}

/// Body of a request that records the user's answer to a notice.
public struct RespondRequest: Codable, Sendable, Equatable {
    public var action: String
    public var text: String?

    public init(action: String, text: String? = nil) {
        self.action = action
        self.text = text
    }
}

/// Body of a request that moves a notice to a lifecycle state.
public struct NoticeStateRequest: Codable, Sendable, Equatable {
    public var state: String

    public init(state: String) {
        self.state = state
    }
}
