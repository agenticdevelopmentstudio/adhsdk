// Tests/AgenticDeveloperHubSDKMacOSTests/Chat/ChatDayBannerConformanceTests.swift
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKUI
import AppKit
import XCTest
@testable import AgenticDeveloperHubSDKMacOS

/// Conformance vectors chat-day-banner-001 ... chat-day-banner-016.
///
/// `TranscriptDateTests` covers the day a banner names and where a transcript
/// puts it; this file covers what the banner is made of: its layout, its
/// accessibility and how it follows the theme.
@MainActor
final class ChatDayBannerConformanceTests: XCTestCase {

    private final class DayBannerThemeStorage: ThemeStorage {
        var customThemes: [ColorTheme] = []
        var activeThemeID: String?
        var onExternalChange: (() -> Void)?
    }

    private var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }

    /// A calendar on the zone the banner's own formatter runs in, so the day a
    /// banner is built from and the day its text names cannot disagree.
    private var localCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }

    private func instant(
        _ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0, _ second: Int = 0,
        in calendar: Calendar
    ) throws -> Date {
        let components = DateComponents(year: year, month: month, day: day,
                                        hour: hour, minute: minute, second: second)
        return try XCTUnwrap(calendar.date(from: components))
    }

    /// "Wednesday, June 3 2026" in the words the machine's own locale uses.
    private func expectedJune3Text() -> String {
        let formatter = DateFormatter()
        return "\(formatter.weekdaySymbols[3]), \(formatter.monthSymbols[5]) 3 2026"
    }

    private func label(of banner: ChatDayBannerView) throws -> NSTextField {
        try XCTUnwrap(banner.subviews.compactMap { $0 as? NSTextField }.first)
    }

    private func rules(of banner: ChatDayBannerView) -> [NSView] {
        banner.subviews.filter { !($0 is NSTextField) }
    }

    /// Pins `banner` to the top and both sides of a view `width` wide and lays it out.
    private func host(_ banner: ChatDayBannerView, width: CGFloat) -> NSView {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: width, height: 200))
        container.addSubview(banner)
        NSLayoutConstraint.activate([
            banner.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            banner.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            banner.topAnchor.constraint(equalTo: container.topAnchor)
        ])
        container.layoutSubtreeIfNeeded()
        return container
    }

    private func june3Banner() throws -> ChatDayBannerView {
        ChatDayBannerView(day: try instant(2026, 6, 3, in: localCalendar), calendar: localCalendar)
    }

    // MARK: - Day

    func testV001_theLabelSpellsOutTheDay() throws {
        let banner = try june3Banner()
        XCTAssertEqual(try label(of: banner).stringValue, expectedJune3Text())
        XCTAssertTrue(banner.title.hasSuffix(" 3 2026"), "\"\(banner.title)\" is not day, then year")
    }

    func testV002_theDayIsNormalizedToTheStartOfItsDayInTheCalendarsZone() throws {
        let late = try instant(2026, 6, 3, 23, 59, 59, in: utc)
        let banner = ChatDayBannerView(day: late, calendar: utc)
        XCTAssertEqual(banner.day, try instant(2026, 6, 3, 0, 0, 0, in: utc))
        XCTAssertNotEqual(banner.day, late)
    }

    func testV003_twoInstantsOnOneDayShareADayAndATitle() throws {
        let calendar = localCalendar
        let early = ChatDayBannerView(day: try instant(2026, 6, 3, 0, 5, in: calendar), calendar: calendar)
        let late = ChatDayBannerView(day: try instant(2026, 6, 3, 23, 50, in: calendar), calendar: calendar)
        XCTAssertEqual(early.day, late.day)
        XCTAssertEqual(early.title, late.title)

        let pinned = ChatDayBannerView(day: try instant(2026, 6, 3, 0, 5, in: utc), calendar: utc)
        let pinnedLate = ChatDayBannerView(day: try instant(2026, 6, 3, 23, 50, in: utc), calendar: utc)
        XCTAssertEqual(pinned.day, pinnedLate.day)
    }

    // MARK: - Layout

    func testV004_theLabelIsCenteredInTheView() throws {
        let banner = try june3Banner()
        _ = host(banner, width: 600)
        XCTAssertEqual(try label(of: banner).frame.midX, banner.bounds.midX, accuracy: 0.5)
    }

    func testV005_theRulesSitTenPointsFromTheLabel() throws {
        let banner = try june3Banner()
        _ = host(banner, width: 600)
        // The rules are pinned to the label's anchors, which are its alignment
        // rect; a text field's frame is wider by its built-in padding.
        let text = try label(of: banner)
        let field = text.alignmentRect(forFrame: text.frame)
        let found = rules(of: banner).sorted { $0.frame.minX < $1.frame.minX }
        XCTAssertEqual(found.count, 2)
        XCTAssertEqual(try XCTUnwrap(found.first).frame.maxX, field.minX - 10, accuracy: 0.01)
        XCTAssertEqual(try XCTUnwrap(found.last).frame.minX, field.maxX + 10, accuracy: 0.01)
        XCTAssertEqual(try XCTUnwrap(found.first).frame.minX, 0, accuracy: 0.01)
        XCTAssertEqual(try XCTUnwrap(found.last).frame.maxX, banner.bounds.maxX, accuracy: 0.01)
    }

    func testV006_theRulesStayEqualWhateverTheDateSays() throws {
        let short = ChatDayBannerView(day: try instant(2026, 5, 4, in: localCalendar), calendar: localCalendar)
        let long = ChatDayBannerView(day: try instant(2026, 9, 30, in: localCalendar), calendar: localCalendar)
        for banner in [short, long] {
            _ = host(banner, width: 600)
            let found = rules(of: banner).sorted { $0.frame.minX < $1.frame.minX }
            XCTAssertEqual(try XCTUnwrap(found.first).frame.width, try XCTUnwrap(found.last).frame.width,
                           accuracy: 0.01, "\"\(banner.title)\" put its rules out of step")
            XCTAssertEqual(try label(of: banner).frame.midX, banner.bounds.midX, accuracy: 0.5)
        }
        XCTAssertNotEqual(try label(of: short).frame.width, try label(of: long).frame.width,
                          "the two dates are as wide as each other, so this proves nothing")
    }

    func testV007_theBannerKeepsSixteenAboveAndEightBelowItsLabel() throws {
        let banner = try june3Banner()
        _ = host(banner, width: 600)
        let field = try label(of: banner).frame
        XCTAssertEqual(banner.bounds.maxY - field.maxY, 16, accuracy: 0.01)
        XCTAssertEqual(field.minY, 8, accuracy: 0.01)
    }

    func testV008_theRulesAreOnePointTallAndCenteredOnTheLabel() throws {
        let banner = try june3Banner()
        _ = host(banner, width: 600)
        let field = try label(of: banner).frame
        for rule in rules(of: banner) {
            XCTAssertEqual(rule.frame.height, 1, accuracy: 0.01)
            XCTAssertEqual(rule.frame.midY, field.midY, accuracy: 0.5)
        }
    }

    // MARK: - Accessibility

    func testV009_theBannerIsStaticText() throws {
        XCTAssertEqual(try june3Banner().accessibilityRole(), .staticText)
    }

    func testV010_theLabelsAccessibilityLabelIsItsText() throws {
        let field = try label(of: try june3Banner())
        XCTAssertEqual(field.accessibilityLabel(), field.stringValue)
        XCTAssertEqual(field.accessibilityLabel(), expectedJune3Text())
    }

    func testV011_theLabelCarriesTheChatDayBannerIdentifier() throws {
        XCTAssertEqual(try label(of: try june3Banner()).accessibilityIdentifier(), "chat-day-banner")
    }

    // MARK: - Theme

    func testV012_aThemeChangeRestylesTheSameBanner() throws {
        let storage = DayBannerThemeStorage()
        storage.activeThemeID = BuiltInThemes.dracula.id
        let manager = ThemeManager(storage: storage, appearanceDriver: nil)
        defer { withExtendedLifetime(manager) {} }
        let banner = try june3Banner()
        let field = try label(of: banner)
        let found = rules(of: banner)
        let identity = ObjectIdentifier(banner)

        func assertStyled(by palette: SemanticPalette, file: StaticString = #filePath, line: UInt = #line) {
            XCTAssertEqual(field.font, palette.font(.caption), "the label's font", file: file, line: line)
            XCTAssertEqual(field.textColor, palette.nsColor(.timestampText), "the label's color",
                           file: file, line: line)
            for rule in found {
                XCTAssertEqual(rule.layer?.backgroundColor, palette.nsColor(.divider).cgColor,
                               "a rule's color", file: file, line: line)
            }
        }
        let first = manager.currentPalette
        assertStyled(by: first)

        manager.selectTheme(id: BuiltInThemes.nord.id)
        let second = manager.currentPalette

        XCTAssertNotEqual(first.nsColor(.timestampText), second.nsColor(.timestampText),
                          "the two themes agree on this color, so this proves nothing")
        XCTAssertNotEqual(first.nsColor(.divider), second.nsColor(.divider))
        assertStyled(by: second)
        XCTAssertEqual(ObjectIdentifier(banner), identity)
    }

    // MARK: - Properties

    func testV013_dayAndTitleAreExposed() throws {
        let calendar = localCalendar
        let banner = ChatDayBannerView(day: try instant(2026, 6, 3, 17, 30, in: calendar), calendar: calendar)
        XCTAssertEqual(banner.day, try instant(2026, 6, 3, 0, 0, 0, in: calendar))
        XCTAssertEqual(banner.title, try label(of: banner).stringValue)
        XCTAssertEqual(banner.title, expectedJune3Text())
    }

    func testV014_constructionFromAnArchive() throws {
        throw XCTSkip("init(coder:) is marked unavailable, a compile-time error, and is a fatalError at runtime")
    }

    // MARK: - Narrow view

    func testV015_aNarrowViewNarrowsTheRulesTogetherAndKeepsTheLabelOnOneLine() throws {
        let day = try instant(2026, 9, 30, in: localCalendar)
        let wide = ChatDayBannerView(day: day, calendar: localCalendar)
        _ = host(wide, width: 600)
        let wideLabel = try label(of: wide).frame
        let wideRule = try XCTUnwrap(rules(of: wide).first).frame.width

        // Room for the label, its two gaps and five points of rule either side.
        let narrow = ChatDayBannerView(day: day, calendar: localCalendar)
        _ = host(narrow, width: wideLabel.width + 20 + 10)
        let narrowLabel = try label(of: narrow).frame
        let found = rules(of: narrow).sorted { $0.frame.minX < $1.frame.minX }

        XCTAssertEqual(narrowLabel.height, wideLabel.height, accuracy: 0.01, "the label wrapped onto a second line")
        XCTAssertEqual(narrowLabel.width, wideLabel.width, accuracy: 0.5)
        XCTAssertEqual(try XCTUnwrap(found.first).frame.width, try XCTUnwrap(found.last).frame.width, accuracy: 0.01)
        XCTAssertLessThan(try XCTUnwrap(found.first).frame.width, wideRule)
        XCTAssertEqual(narrowLabel.midX, narrow.bounds.midX, accuracy: 0.5)
    }

    func testV016_confinementToTheUIThread() throws {
        throw XCTSkip("the class is @MainActor, so the compiler refuses off-thread use; there is no runtime check")
    }
}
