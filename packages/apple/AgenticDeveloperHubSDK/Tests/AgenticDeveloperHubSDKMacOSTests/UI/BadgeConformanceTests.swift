import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKUI
import AppKit
import XCTest
@testable import AgenticDeveloperHubSDKMacOS

/// Conformance vectors badge-001 ... badge-016. Every color is an explicit sRGB
/// value, never a system color, so no vector depends on the appearance mode.
@MainActor
final class BadgeConformanceTests: XCTestCase {

    private final class BadgeThemeStorage: ThemeStorage {
        var customThemes: [ColorTheme] = []
        var activeThemeID: String?
        var onExternalChange: (() -> Void)?
    }

    private static let green = NSColor(srgbRed: 0, green: 0.6, blue: 0, alpha: 1)
    private static let red = NSColor(srgbRed: 0.8, green: 0, blue: 0, alpha: 1)
    private static let blue = NSColor(srgbRed: 0, green: 0, blue: 0.9, alpha: 1)
    private static let gray = NSColor(srgbRed: 0.5, green: 0.5, blue: 0.5, alpha: 1)

    private func label(of badge: Badge) throws -> NSTextField {
        try XCTUnwrap(badge.subviews.compactMap { $0 as? NSTextField }.first)
    }

    private func textColor(onBackground color: NSColor) throws -> NSColor? {
        let badge = Badge(text: "x", color: color)
        return try label(of: badge).textColor
    }

    func testBadge001_backgroundIsARoundedPillWithRadiusFive() {
        let badge = Badge(text: "dev", color: Self.green)
        XCTAssertEqual(badge.layer?.cornerRadius, 5)
    }

    func testBadge002_labelShowsTheCallerText() throws {
        let badge = Badge(text: "dev", color: Self.green)
        XCTAssertEqual(try label(of: badge).stringValue, "dev")
    }

    func testBadge003_defaultsToTheFilledStyle() {
        let badge = Badge(text: "dev", color: Self.green)
        XCTAssertEqual(badge.layer?.backgroundColor, Self.green.cgColor)
        XCTAssertEqual(badge.layer?.borderWidth, 0)
    }

    func testBadge004_filledStylePaintsTheColorAndNoBorder() {
        let badge = Badge(text: "dev", color: Self.green, style: .filled)
        XCTAssertEqual(badge.layer?.backgroundColor, Self.green.cgColor)
        XCTAssertEqual(badge.layer?.borderWidth, 0)
    }

    func testBadge005_lightBackgroundGetsBlackText() throws {
        let light = NSColor(srgbRed: 0.902, green: 0.902, blue: 0.902, alpha: 1)
        XCTAssertEqual(try textColor(onBackground: light), .black)
    }

    func testBadge005b_darkBackgroundGetsWhiteText() throws {
        let navy = NSColor(srgbRed: 0, green: 0, blue: 0.502, alpha: 1)
        XCTAssertEqual(try textColor(onBackground: navy), .white)
    }

    func testBadge005c_luminanceExactlyAtTheThresholdGetsWhiteText() throws {
        let boundary = NSColor(srgbRed: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        XCTAssertEqual(try textColor(onBackground: boundary), .white)
    }

    func testBadge006_colorThatCannotConvertToSRGBFallsBackToWhiteText() throws {
        let pattern = NSColor(patternImage: NSImage(size: NSSize(width: 2, height: 2)))
        try XCTSkipIf(
            pattern.usingColorSpace(.sRGB) != nil,
            "this macOS converts a pattern color to sRGB, so there is no unconvertible color to feed in")
        XCTAssertEqual(try textColor(onBackground: pattern), .white)
    }

    func testBadge007_outlinedStyleIsClearWithAOnePointBorderAndColoredText() throws {
        let badge = Badge(text: "3", color: Self.red, style: .outlined)
        XCTAssertEqual(badge.layer?.backgroundColor, NSColor.clear.cgColor)
        XCTAssertEqual(badge.layer?.borderWidth, 1)
        XCTAssertEqual(badge.layer?.borderColor, Self.red.cgColor)
        XCTAssertEqual(try label(of: badge).textColor, Self.red)
    }

    func testBadge008_updateRestylesAnExistingBadgeInPlace() throws {
        let badge = Badge(text: "dev", color: Self.green)
        badge.update(text: "stopped", color: Self.gray, style: .outlined)
        XCTAssertEqual(try label(of: badge).stringValue, "stopped")
        XCTAssertEqual(badge.layer?.backgroundColor, NSColor.clear.cgColor)
        XCTAssertEqual(badge.layer?.borderWidth, 1)
        XCTAssertEqual(badge.layer?.borderColor, Self.gray.cgColor)
        XCTAssertEqual(try label(of: badge).textColor, Self.gray)
    }

    func testBadge009_updateWithoutAStyleResetsToFilled() throws {
        let badge = Badge(text: "x", color: Self.red, style: .outlined)
        badge.update(text: "3", color: Self.blue)
        XCTAssertEqual(badge.layer?.backgroundColor, Self.blue.cgColor)
        XCTAssertEqual(badge.layer?.borderWidth, 0)
        XCTAssertEqual(try label(of: badge).stringValue, "3")
    }

    func testBadge010_labelIsInsetSixPointsSideways_twoVertically() throws {
        let badge = Badge(text: "dev", color: Self.green)
        let field = try label(of: badge)
        func constant(_ attribute: NSLayoutConstraint.Attribute) throws -> CGFloat {
            try XCTUnwrap(badge.constraints.first {
                $0.firstItem === field && $0.firstAttribute == attribute
            }).constant
        }
        XCTAssertEqual(try constant(.leading), 6)
        XCTAssertEqual(try constant(.trailing), -6)
        XCTAssertEqual(try constant(.top), 2)
        XCTAssertEqual(try constant(.bottom), -2)
    }

    func testBadge011_labelTextIsCentered() throws {
        let badge = Badge(text: "dev", color: Self.green)
        XCTAssertEqual(try label(of: badge).alignment, .center)
    }

    func testBadge012_labelFontFollowsTheThemeCaptionFont() throws {
        let manager = ThemeManager(storage: BadgeThemeStorage(), appearanceDriver: nil)
        let badge = Badge(text: "dev", color: Self.green)
        let field = try label(of: badge)
        XCTAssertEqual(field.font, manager.currentPalette.font(.caption))
        let before = field.font

        manager.textScale = 2

        XCTAssertEqual(field.font, manager.currentPalette.font(.caption))
        XCTAssertNotEqual(field.font, before)
        withExtendedLifetime(manager) {}
    }

    func testBadge013_sizesToItsContentAndDoesNotStretch() throws {
        let badge = Badge(text: "dev", color: Self.green)
        let field = try label(of: badge)
        XCTAssertEqual(badge.fittingSize.width, field.intrinsicContentSize.width + 12, accuracy: 0.5)

        let container = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 100))
        container.addSubview(badge)
        NSLayoutConstraint.activate([
            badge.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            badge.topAnchor.constraint(equalTo: container.topAnchor)
        ])
        container.layoutSubtreeIfNeeded()
        XCTAssertEqual(badge.frame.width, field.intrinsicContentSize.width + 12, accuracy: 0.5)
        XCTAssertLessThan(badge.frame.width, 500)
    }

    func testBadge014_confinementToTheUIThread() throws {
        throw XCTSkip("Badge is @MainActor, so off-thread use is rejected at build time; no test can express it")
    }

    func testBadge015_storyboardInstantiationIsRefusedByInspectionOnly() throws {
        throw XCTSkip("init(coder:) calls fatalError; the refusal terminates the process and cannot be caught")
    }

    func testBadge016_outlinedTextAndBorderAreExactlyTheColorWithNoContrastAdjustment() throws {
        let nearHost = NSColor(srgbRed: 0.97, green: 0.97, blue: 0.97, alpha: 1)
        let badge = Badge(text: "3", color: nearHost, style: .outlined)
        XCTAssertEqual(badge.layer?.borderColor, nearHost.cgColor)
        XCTAssertEqual(try label(of: badge).textColor, nearHost)
    }
}
