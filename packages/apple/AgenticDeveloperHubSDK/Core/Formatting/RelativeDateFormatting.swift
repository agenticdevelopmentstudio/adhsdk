import Foundation

/// The one formatter for a date shown relative to now: `"3 hr. ago"` while the
/// date is recent, and an absolute day (`"Nov 1, 2026"`) once it is more than
/// `cutoff` before now. Stateless; every input, the clock included, is a
/// parameter so tests can fix it.
public enum RelativeDateFormatting {

    /// Seven days: older dates render as an absolute day.
    public static let defaultCutoff: TimeInterval = 7 * 24 * 60 * 60

    /// - Parameters:
    ///   - cutoff: A date more than this many seconds before `now` renders as
    ///     an absolute day; exactly `cutoff` is still relative. `nil` keeps
    ///     every date relative. Future dates are always relative.
    public static func string(
        for date: Date,
        relativeTo now: Date = Date(),
        style: RelativeDateTimeFormatter.UnitsStyle = .abbreviated,
        locale: Locale = .current,
        absoluteAfter cutoff: TimeInterval? = defaultCutoff
    ) -> String {
        if let cutoff, now.timeIntervalSince(date) > cutoff {
            return date.formatted(Date.FormatStyle(locale: locale).year().month(.abbreviated).day())
        }
        // A new formatter per call: style and locale vary, and a shared one
        // would need a lock to be safe across threads.
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = style
        formatter.locale = locale
        return formatter.localizedString(for: date, relativeTo: now)
    }
}
