import Foundation

/// One notification, as it travels from a client through the daemon to every
/// display surface. The daemon stores it, a menubar app renders it, a CLI
/// prints it, and an iOS app lists it — all from this one definition.
///
/// Named `Notice` rather than `Notification` so it never collides with
/// `Foundation.Notification`.
public struct Notice: Codable, Sendable, Equatable, Identifiable {

    /// Severity, least to most urgent. `rank` is what the "minimum level"
    /// preference compares; `rawValue` is what goes over the wire, so the
    /// declaration order of the cases is deliberately not load-bearing.
    public enum Level: String, Codable, Sendable, CaseIterable {
        case info
        case success
        case warning
        case error

        public var rank: Int {
            switch self {
            case .info: 0
            case .success: 1
            case .warning: 2
            case .error: 3
            }
        }
    }

    /// How soon the human should see it, least to most pressing. Independent
    /// of `Level`: a failed nightly build is an `error` that can wait
    /// (`eventually`); a calendar reminder is `info` and cannot (`now`).
    public enum Urgency: String, Codable, Sendable, CaseIterable {
        case fyi
        case eventually
        case soon
        case now
        case emergency

        public var rank: Int {
            switch self {
            case .fyi: 0
            case .eventually: 1
            case .soon: 2
            case .now: 3
            case .emergency: 4
            }
        }
    }

    /// Where a notice stands with the human, as opposed to with a client.
    ///
    /// These are labels, not a ladder: `unread -> acted` is legal without
    /// passing through `read`, and `dismissed` is reachable from any of them.
    /// Delivery — whether a given client has acked this notice — is a different
    /// question entirely, answered per (notice, client) by the delivery ledger.
    public enum Lifecycle: String, Codable, Sendable, CaseIterable {
        case unread
        case read
        case acted
        case dismissed
        case snoozed
        case archived
        case expired

        /// Waiting for the user. Presenters show only these.
        public var isActive: Bool { self == .unread }

        /// Finished with: acted on, dismissed, archived or expired.
        public var isConsumed: Bool {
            switch self {
            case .acted, .archived, .dismissed, .expired: true
            case .unread, .read, .snoozed: false
            }
        }
    }

    /// Daemon-assigned when the client omits it.
    public var id: String
    /// Daemon-assigned when the client omits it. ISO-8601 on the wire.
    public var timestamp: Date
    /// Who raised it — "claude-code", "ci", the name of a script.
    public var source: String
    public var title: String
    public var subtitle: String?
    /// The longer text. The UI calls it "details"; on the wire it is `body`.
    public var body: String?
    /// The issuing app's bundle id; gives the icon and an "open app" fallback.
    public var app: String?
    public var level: Level
    public var urgency: Urgency
    public var category: String?
    /// Opaque client data. It doubles as the filter key space for SSE and XPC
    /// subscriptions, so subscribers need no second filtering vocabulary.
    public var metadata: [String: String]
    /// What the user can do about it. The first is the primary action.
    public var actions: [Action]
    /// After this the notice expires. Clients may send `ttl` seconds instead.
    public var expiresAt: Date?
    /// Replace-key, scoped to `source`: a new notice with the same key
    /// archives the older ones.
    public var key: String?
    /// Where this notice stands with the human. Daemon-owned: a client posting
    /// a notice does not get to declare it already read.
    public var state: Lifecycle
    /// When `state` last changed. `nil` while the notice is still `.unread`.
    public var stateAt: Date?
    /// When a snoozed notice comes back. Daemon-owned.
    public var snoozedUntil: Date?
    /// How the user answered. Daemon-owned; set when the user acts.
    public var response: NoticeResponse?

    public init(
        id: String = UUID().uuidString,
        timestamp: Date = Date(),
        source: String,
        title: String,
        subtitle: String? = nil,
        body: String? = nil,
        app: String? = nil,
        level: Level = .info,
        urgency: Urgency = .fyi,
        category: String? = nil,
        metadata: [String: String] = [:],
        actions: [Action] = [],
        expiresAt: Date? = nil,
        key: String? = nil,
        state: Lifecycle = .unread,
        stateAt: Date? = nil,
        snoozedUntil: Date? = nil,
        response: NoticeResponse? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.source = source
        self.title = title
        self.subtitle = subtitle
        self.body = body
        self.app = app
        self.level = level
        self.urgency = urgency
        self.category = category
        self.metadata = metadata
        self.actions = actions
        self.expiresAt = expiresAt
        self.key = key
        self.state = state
        self.stateAt = stateAt
        self.snoozedUntil = snoozedUntil
        self.response = response
    }

    /// The action a one-click presentation runs.
    public var primaryAction: Action? { actions.first }
}
