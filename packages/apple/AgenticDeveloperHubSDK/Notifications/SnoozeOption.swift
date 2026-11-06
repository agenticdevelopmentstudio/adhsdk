import Foundation

/// The snooze choices a notice offers.
public enum SnoozeOption: Sendable, Equatable, CaseIterable {
    case fiveMinutes
    case fifteenMinutes
    case oneHour
    case tomorrowMorning
    /// 24 hours out; the app wakes the notice early when the user returns.
    case untilBack

    public var title: String {
        switch self {
        case .fiveMinutes: "5 minutes"
        case .fifteenMinutes: "15 minutes"
        case .oneHour: "1 hour"
        case .tomorrowMorning: "Tomorrow at 9:00"
        case .untilBack: "Until I'm back"
        }
    }

    /// When the snoozed notice comes back. `tomorrowMorning` is 09:00 on the
    /// next calendar day in `calendar.timeZone`, so a DST change between now
    /// and then does not shift it.
    public func until(now: Date, calendar: Calendar) -> Date {
        switch self {
        case .fiveMinutes: return now.addingTimeInterval(5 * 60)
        case .fifteenMinutes: return now.addingTimeInterval(15 * 60)
        case .oneHour: return now.addingTimeInterval(60 * 60)
        case .untilBack: return now.addingTimeInterval(24 * 60 * 60)
        case .tomorrowMorning:
            let today = calendar.startOfDay(for: now)
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today.addingTimeInterval(86_400)
            return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) ?? tomorrow
        }
    }
}
