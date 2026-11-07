import Foundation

/// How one urgency (or override) presents a notice: every item in `items` is
/// shown at once, each by its own presenter. An empty set means "don't show".
///
/// Dismiss timing and snooze belong to the set, not to its items, so a toast
/// and its Notification Center copy always agree.
public struct NoticeStyleSet: Codable, Sendable, Equatable {
    public var items: [NoticeProfile]
    /// Seconds before the notice goes away; nil means never.
    public var autoDismiss: TimeInterval?
    public var snooze: SnoozeSettings

    public init(items: [NoticeProfile], autoDismiss: TimeInterval? = nil, snooze: SnoozeSettings = .init()) {
        self.items = items
        self.autoDismiss = autoDismiss
        self.snooze = snooze
    }

    /// `items` as presenters receive them: each carries the set's dismiss.
    public var presentedItems: [NoticeProfile] {
        items.map { item in
            var stamped = item
            stamped.autoDismiss = autoDismiss
            return stamped
        }
    }

    /// The same set with nothing to show: what a `.hide` override resolves to.
    public var hidden: NoticeStyleSet {
        NoticeStyleSet(items: [], autoDismiss: autoDismiss, snooze: snooze)
    }

    private enum CodingKeys: String, CodingKey {
        case items, autoDismiss, snooze
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            items: try container.decodeIfPresent([NoticeProfile].self, forKey: .items) ?? [],
            autoDismiss: try container.decodeIfPresent(TimeInterval.self, forKey: .autoDismiss),
            snooze: try container.decodeIfPresent(SnoozeSettings.self, forKey: .snooze) ?? .init())
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(items, forKey: .items)
        try container.encodeIfPresent(autoDismiss, forKey: .autoDismiss)
        try container.encode(snooze, forKey: .snooze)
    }
}

/// Whether a set's notices can be snoozed, and to which times.
public struct SnoozeSettings: Codable, Sendable, Equatable {
    public var isEnabled: Bool
    /// Always in `SnoozeOption.allCases` order, without duplicates.
    public var options: [SnoozeOption] {
        didSet { options = Self.normalized(options) }
    }

    public var isSnoozable: Bool { isEnabled && !options.isEmpty }

    public init(isEnabled: Bool = true, options: [SnoozeOption] = SnoozeOption.allCases) {
        self.isEnabled = isEnabled
        self.options = Self.normalized(options)
    }

    private static func normalized(_ options: [SnoozeOption]) -> [SnoozeOption] {
        SnoozeOption.allCases.filter(options.contains)
    }

    private enum CodingKeys: String, CodingKey {
        case isEnabled, options
    }

    /// An option this build doesn't know is skipped, not a decode failure.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let raw = try container.decodeIfPresent([String].self, forKey: .options)
        self.init(
            isEnabled: try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true,
            options: raw?.compactMap(SnoozeOption.init(rawValue:)) ?? SnoozeOption.allCases)
    }
}
