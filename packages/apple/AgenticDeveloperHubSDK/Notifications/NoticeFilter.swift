import Foundation

/// The user's "which notices do I want to see" preferences, as a predicate.
///
/// Every app asks the same question of the same preferences — a macOS app
/// before presenting, an iOS app before showing a row — so the answer is
/// defined once, here, rather than in each UI layer where it would drift.
///
/// It is a value with no dependency on how the preferences are stored: callers
/// read them from user defaults, `@AppStorage` or a test literal and hand over
/// the strings.
public struct NoticeFilter: Sendable, Equatable {

    /// Notices below this level are excluded.
    public let minimumLevel: Notice.Level

    /// Category names, case-folded, that are excluded regardless of level.
    public let mutedCategories: Set<String>

    /// A notice whose metadata carries ANY of these key/value pairs is excluded.
    /// This is how a host drops a class of notice (for example copies it
    /// ingested from elsewhere) without the SDK knowing the host's vocabulary.
    public var excludedMetadata: [String: String]

    /// - Parameters:
    ///   - minimumLevelRawValue: a `Notice.Level` raw value. An unrecognized
    ///     string — a downgrade, a hand-edited default — falls back to `.info`
    ///     rather than excluding everything: a bad preference should show too
    ///     much, never silently swallow the lot.
    ///   - mutedCategories: the raw comma-separated field as the user typed it.
    ///   - excludedMetadata: metadata pairs that exclude a notice.
    public init(
        minimumLevelRawValue: String,
        mutedCategories: String,
        excludedMetadata: [String: String] = [:]
    ) {
        self.minimumLevel = Notice.Level(rawValue: minimumLevelRawValue) ?? .info
        self.mutedCategories = Self.categoryList(mutedCategories)
        self.excludedMetadata = excludedMetadata
    }

    public init(
        minimumLevel: Notice.Level = .info,
        mutedCategories: Set<String> = [],
        excludedMetadata: [String: String] = [:]
    ) {
        self.minimumLevel = minimumLevel
        self.mutedCategories = mutedCategories
        self.excludedMetadata = excludedMetadata
    }

    /// Splits the free-text muted-categories field.
    ///
    /// Free text because categories are coined by whoever posts the notice, so
    /// there is no fixed list to offer. Trimmed and case-folded so `CI`, `ci `
    /// and ` Ci` are one category.
    public static func categoryList(_ raw: String) -> Set<String> {
        Set(
            raw.split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                .filter { !$0.isEmpty }
        )
    }

    /// Whether this notice passes every gate.
    public func admits(_ notice: Notice) -> Bool {
        guard notice.level.rank >= minimumLevel.rank else { return false }
        for (key, value) in excludedMetadata where notice.metadata[key] == value {
            return false
        }
        guard let category = notice.category?.lowercased() else { return true }
        return !mutedCategories.contains(category)
    }
}

public extension Sequence<Notice> {
    /// The notices this filter admits, order preserved.
    func admitted(by filter: NoticeFilter) -> [Notice] {
        self.filter(filter.admits)
    }
}
