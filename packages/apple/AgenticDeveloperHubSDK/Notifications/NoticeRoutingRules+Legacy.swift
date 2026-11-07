import Foundation

/// Reading rules stored by 0.7.x, where each urgency had one `NoticeProfile`
/// with its own screens, dismiss and "also post to Notification Center".
/// Encoding never writes this shape, so the next save completes the move.
extension NoticeRoutingRules {

    /// The parts of a 0.7.x value that changed shape.
    struct Legacy {
        var styles: [Notice.Urgency: NoticeStyleSet]
        var overrides: [Override]
        var screens: ScreenSelection
        var crawlLeftToRight: Bool?
        var hotkeysEnabled: Bool?
    }

    private enum LegacyKeys: String, CodingKey {
        case styles, profiles, overrides, crawlLeftToRight, hotkeysEnabled
    }

    /// A 0.7.x profile, every field read as loosely as the old decoder did.
    private struct LegacyProfile: Decodable {
        var style: String
        var position: String?
        var screens: String?
        var layer: String?
        var autoDismiss: TimeInterval?
        var forwardToSystem: Bool?

        /// `none` becomes an empty set; forwarding adds a system item.
        var set: NoticeStyleSet {
            var items: [NoticeProfile] = []
            if let style = NoticeProfile.Style(rawValue: self.style) {
                items.append(NoticeProfile(
                    style: style,
                    position: NoticeProfile.position(decoding: position, for: style),
                    layer: layer.flatMap(NoticeProfile.Layer.init(rawValue:)) ?? .floating))
            }
            if forwardToSystem == true, !items.contains(where: { $0.style == .system }) {
                items.append(NoticeProfile(style: .system))
            }
            return NoticeStyleSet(items: items, autoDismiss: autoDismiss)
        }
    }

    private struct LegacyOverride: Decodable {
        var source: String?
        var category: String?
        var urgency: Notice.Urgency?
        var profile: LegacyProfile
    }

    /// The converted legacy fields, or nil when `decoder` holds the current
    /// shape (or no `profiles` at all).
    static func decodeLegacy(from decoder: Decoder) throws -> Legacy? {
        let container = try decoder.container(keyedBy: LegacyKeys.self)
        guard !container.contains(.styles),
              let profiles = try container.decodeIfPresent([String: LegacyProfile].self, forKey: .profiles)
        else { return nil }

        var styles: [Notice.Urgency: NoticeStyleSet] = [:]
        var urgencyProfiles: [LegacyProfile] = []
        for urgency in Notice.Urgency.allCases {
            if let profile = profiles[urgency.rawValue] {
                urgencyProfiles.append(profile)
                styles[urgency] = profile.set
            } else {
                styles[urgency] = defaultStyle(for: urgency)
            }
        }
        let allMain = !urgencyProfiles.isEmpty && urgencyProfiles.allSatisfy { $0.screens == "main" }

        let overrides = try container.decodeLossyArrayIfPresent([LegacyOverride].self, forKey: .overrides) ?? []
        return Legacy(
            styles: styles,
            overrides: overrides.map { old in
                Override(source: old.source, category: old.category, urgency: old.urgency,
                         target: target(for: old.profile, in: styles))
            },
            screens: allMain ? .main : .all,
            crawlLeftToRight: try container.decodeIfPresent(Bool.self, forKey: .crawlLeftToRight),
            hotkeysEnabled: try container.decodeIfPresent(Bool.self, forKey: .hotkeysEnabled))
    }

    /// `none` hides; any other style points at the first urgency whose set
    /// leads with it, or at `fyi` when none does.
    private static func target(
        for profile: LegacyProfile, in styles: [Notice.Urgency: NoticeStyleSet]
    ) -> Override.Target {
        guard let style = NoticeProfile.Style(rawValue: profile.style) else { return .hide }
        let match = Notice.Urgency.allCases.first { styles[$0]?.items.first?.style == style }
        return .style(match ?? .fyi)
    }
}
