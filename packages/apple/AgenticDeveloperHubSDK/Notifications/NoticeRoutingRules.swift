import Foundation

/// Which profile presents which notice: one profile per urgency, plus an
/// ordered list of overrides that are tried first.
public struct NoticeRoutingRules: Codable, Sendable, Equatable {

    /// Narrows by source, category and/or urgency. Every non-nil field must match.
    public struct Override: Codable, Sendable, Equatable {
        public var source: String?
        public var category: String?
        public var urgency: Notice.Urgency?
        public var profile: NoticeProfile

        public init(
            source: String? = nil,
            category: String? = nil,
            urgency: Notice.Urgency? = nil,
            profile: NoticeProfile
        ) {
            self.source = source
            self.category = category
            self.urgency = urgency
            self.profile = profile
        }

        func matches(_ notice: Notice, urgency effective: Notice.Urgency) -> Bool {
            if let source, source != notice.source { return false }
            if let category {
                guard let found = notice.category, found.lowercased() == category.lowercased() else { return false }
            }
            if let urgency, urgency != effective { return false }
            return true
        }
    }

    public var profiles: [Notice.Urgency: NoticeProfile]
    public var overrides: [Override]
    public var toastStackLimit: Int
    public var flood: FloodFolder.Configuration
    public var escalation: EscalationPolicy
    public var hideFromScreenSharing: Bool
    public var hotkeysEnabled: Bool
    public var crawlLeftToRight: Bool

    public init(
        profiles: [Notice.Urgency: NoticeProfile],
        overrides: [Override] = [],
        toastStackLimit: Int = 4,
        flood: FloodFolder.Configuration = .init(),
        escalation: EscalationPolicy = .init(),
        hideFromScreenSharing: Bool = true,
        hotkeysEnabled: Bool = true,
        crawlLeftToRight: Bool = false
    ) {
        self.profiles = profiles
        self.overrides = overrides
        self.toastStackLimit = toastStackLimit
        self.flood = flood
        self.escalation = escalation
        self.hideFromScreenSharing = hideFromScreenSharing
        self.hotkeysEnabled = hotkeysEnabled
        self.crawlLeftToRight = crawlLeftToRight
    }

    private static func defaultProfile(for urgency: Notice.Urgency) -> NoticeProfile {
        switch urgency {
        case .fyi:
            NoticeProfile(style: .toast, position: .topRight, screens: .main, layer: .floating,
                          autoDismiss: 8, forwardToSystem: false)
        case .eventually:
            NoticeProfile(style: .toast, position: .topRight, screens: .main, layer: .floating,
                          autoDismiss: nil, forwardToSystem: false)
        case .soon:
            NoticeProfile(style: .toast, position: .topRight, screens: .cursor, layer: .floating,
                          autoDismiss: nil, forwardToSystem: false)
        case .now:
            NoticeProfile(style: .alert, position: .center, screens: .cursor, layer: .floating,
                          autoDismiss: nil, forwardToSystem: false)
        case .emergency:
            NoticeProfile(style: .fullScreen, position: .center, screens: .all, layer: .floating,
                          autoDismiss: nil, forwardToSystem: false)
        }
    }

    public static let defaults = NoticeRoutingRules(
        profiles: Dictionary(
            uniqueKeysWithValues: Notice.Urgency.allCases.map { ($0, defaultProfile(for: $0)) }
        )
    )

    /// The profile that presents `notice`. `effectiveUrgency` stands in for the
    /// stored urgency when escalation has raised it. The first matching
    /// override wins; otherwise the urgency's own profile.
    public func profile(for notice: Notice, effectiveUrgency: Notice.Urgency? = nil) -> NoticeProfile {
        let urgency = effectiveUrgency ?? notice.urgency
        if let match = overrides.first(where: { $0.matches(notice, urgency: urgency) }) {
            return match.profile
        }
        return profiles[urgency] ?? Self.defaultProfile(for: urgency)
    }

    /// The retired "deliver notifications" setting defaulted to true, so only a
    /// stored `true` is a choice worth carrying over: it turns on system
    /// forwarding for `fyi`. `nil` and `false` leave the rules alone.
    public static func migratingLegacyDeliverSetting(
        _ value: Bool?, into rules: NoticeRoutingRules
    ) -> NoticeRoutingRules {
        guard value == true else { return rules }
        var migrated = rules
        var fyi = migrated.profile(for: Notice(source: "", title: ""), effectiveUrgency: .fyi)
        fyi.forwardToSystem = true
        migrated.profiles[.fyi] = fyi
        return migrated
    }

    // MARK: Coding
    //
    // A dictionary keyed by a String-backed enum encodes as a flat array, which
    // is unreadable and order-dependent on the wire. Key it by raw value.

    private enum CodingKeys: String, CodingKey {
        case profiles, overrides, toastStackLimit, flood, escalation
        case hideFromScreenSharing, hotkeysEnabled, crawlLeftToRight
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let raw = try container.decode([String: NoticeProfile].self, forKey: .profiles)
        var decoded: [Notice.Urgency: NoticeProfile] = [:]
        for (key, value) in raw {
            if let urgency = Notice.Urgency(rawValue: key) { decoded[urgency] = value }
        }
        self.profiles = decoded
        self.overrides = try container.decode([Override].self, forKey: .overrides)
        self.toastStackLimit = try container.decode(Int.self, forKey: .toastStackLimit)
        self.flood = try container.decode(FloodFolder.Configuration.self, forKey: .flood)
        self.escalation = try container.decode(EscalationPolicy.self, forKey: .escalation)
        self.hideFromScreenSharing = try container.decode(Bool.self, forKey: .hideFromScreenSharing)
        self.hotkeysEnabled = try container.decode(Bool.self, forKey: .hotkeysEnabled)
        self.crawlLeftToRight = try container.decode(Bool.self, forKey: .crawlLeftToRight)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(
            Dictionary(uniqueKeysWithValues: profiles.map { ($0.key.rawValue, $0.value) }),
            forKey: .profiles
        )
        try container.encode(overrides, forKey: .overrides)
        try container.encode(toastStackLimit, forKey: .toastStackLimit)
        try container.encode(flood, forKey: .flood)
        try container.encode(escalation, forKey: .escalation)
        try container.encode(hideFromScreenSharing, forKey: .hideFromScreenSharing)
        try container.encode(hotkeysEnabled, forKey: .hotkeysEnabled)
        try container.encode(crawlLeftToRight, forKey: .crawlLeftToRight)
    }
}
