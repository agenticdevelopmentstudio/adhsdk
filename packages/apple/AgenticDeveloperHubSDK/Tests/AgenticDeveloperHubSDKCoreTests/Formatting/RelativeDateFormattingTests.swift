import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite struct RelativeDateFormattingTests {

    private let locale = Locale(identifier: "en_US")
    private let hour: TimeInterval = 60 * 60
    private let day: TimeInterval = 24 * 60 * 60

    /// Noon local time, so the absolute day never depends on the machine's time zone.
    private func noon(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
        try #require(Calendar.current.date(from: DateComponents(year: year, month: month, day: day, hour: 12)))
    }

    @Test func recentIsRelative() throws {
        let now = try noon(2026, 11, 13)
        let text = RelativeDateFormatting.string(for: now.addingTimeInterval(-3 * hour), relativeTo: now,
                                                 style: .full, locale: locale)
        #expect(text == "3 hours ago")
    }

    @Test func defaultStyleIsAbbreviated() throws {
        let now = try noon(2026, 11, 13)
        let text = RelativeDateFormatting.string(for: now.addingTimeInterval(-3 * hour), relativeTo: now,
                                                 locale: locale)
        #expect(text == "3h ago")
    }

    @Test func olderThanAWeekIsAbsolute() throws {
        let text = RelativeDateFormatting.string(for: try noon(2026, 11, 1), relativeTo: try noon(2026, 11, 13),
                                                 locale: locale)
        #expect(text == "Nov 1, 2026")
    }

    @Test func exactlyTheCutoffIsRelative() throws {
        let now = try noon(2026, 11, 13)
        let text = RelativeDateFormatting.string(for: now.addingTimeInterval(-7 * day), relativeTo: now,
                                                 style: .full, locale: locale)
        #expect(text == "1 week ago")
        let past = RelativeDateFormatting.string(for: now.addingTimeInterval(-7 * day - 1), relativeTo: now,
                                                 style: .full, locale: locale)
        #expect(past == "Nov 6, 2026")
    }

    @Test func noCutoffIsAlwaysRelative() throws {
        let now = try noon(2026, 11, 13)
        let text = RelativeDateFormatting.string(for: now.addingTimeInterval(-400 * day), relativeTo: now,
                                                 style: .full, locale: locale, absoluteAfter: nil)
        #expect(text == "1 year ago")
    }

    @Test func futureIsRelative() throws {
        let now = try noon(2026, 11, 13)
        let text = RelativeDateFormatting.string(for: now.addingTimeInterval(30 * day), relativeTo: now,
                                                 style: .full, locale: locale)
        #expect(text == "in 1 month")
    }

    @Test func defaultCutoffIsSevenDays() {
        #expect(RelativeDateFormatting.defaultCutoff == 604_800)
    }
}
