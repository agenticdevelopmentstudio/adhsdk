import Foundation

/// What the daemon broadcasts when a notice's state moves without a new
/// notice arriving, so every presenter can drop or restore its card.
public struct NoticeStateChange: Codable, Sendable, Equatable {

    public var id: String
    public var state: Notice.Lifecycle
    public var stateAt: Date
    public var snoozedUntil: Date?

    public init(id: String, state: Notice.Lifecycle, stateAt: Date, snoozedUntil: Date? = nil) {
        self.id = id
        self.state = state
        self.stateAt = stateAt
        self.snoozedUntil = snoozedUntil
    }
}
