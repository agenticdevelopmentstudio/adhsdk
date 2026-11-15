// Tests/AgenticDeveloperHubSDKMacOSTests/Chat/AIChatBubbleViewConformanceTests.swift
import AgenticDeveloperHubSDKCoreUI
import AgenticDeveloperHubSDKUI
import AppKit
import XCTest
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKCoreMacOS
@testable import AgenticDeveloperHubSDKMacOS

/// Conformance vectors chat-bubble-001 ... chat-bubble-022: what a bubble is
/// painted in, how it is bordered and what its text and timestamp are set in.
///
/// `BubbleStyleTests` and `BubbleTruncationTests` cover the terminal box, the
/// muted work output and the cut in broad strokes; these pin each vector of the
/// recipe, one test apiece. The rest are in `AIChatBubbleLayoutConformanceTests`.
@MainActor
final class AIChatBubbleViewConformanceTests: AIChatBubbleConformanceCase {

    // MARK: - Corner radius

    func testV001_speakerCornerRadiusIsTwelve() throws {
        XCTAssertEqual(try XCTUnwrap(bubble(style: .speaker).layer).cornerRadius, 12)
    }

    func testV002_terminalCornerRadiusIsSix() throws {
        XCTAssertEqual(try XCTUnwrap(bubble(style: .terminal).layer).cornerRadius, 6)
    }

    // MARK: - Role colors

    func testV003_userUsesUserBubbleAndUserText() throws {
        let made = bubble(role: .user)
        XCTAssertEqual(try XCTUnwrap(made.layer).backgroundColor, palette.nsColor(.userBubble).cgColor)
        XCTAssertEqual(try textColor(of: made), palette.nsColor(.userText))
    }

    func testV004_assistantUsesPersonaBubbleAndPersonaText() throws {
        let made = bubble(role: .assistant)
        XCTAssertEqual(try XCTUnwrap(made.layer).backgroundColor, palette.nsColor(.personaBubble).cgColor)
        XCTAssertEqual(try textColor(of: made), palette.nsColor(.personaText))
    }

    func testV005_errorIsDangerAtEightPercentWithDangerText() throws {
        let made = bubble(role: .error)
        let danger = palette.nsColor(.danger)
        XCTAssertEqual(try XCTUnwrap(made.layer).backgroundColor, danger.withAlphaComponent(0.08).cgColor)
        XCTAssertEqual(try textColor(of: made), danger)
    }

    func testV006_noticeIsSecondaryTextAtTenPercentWithSecondaryText() throws {
        let made = bubble(role: .notice)
        let secondary = palette.nsColor(.secondaryText)
        XCTAssertEqual(try XCTUnwrap(made.layer).backgroundColor, secondary.withAlphaComponent(0.10).cgColor)
        XCTAssertEqual(try textColor(of: made), secondary)
    }

    // MARK: - Terminal style

    func testV007_terminalUserIsTheSurfaceAndBorderNotTheUserBubble() throws {
        let layer = try XCTUnwrap(bubble(role: .user, style: .terminal).layer)
        XCTAssertEqual(layer.backgroundColor, palette.nsColor(.surface).cgColor)
        XCTAssertEqual(layer.borderColor, palette.nsColor(.border).cgColor)
        XCTAssertNotEqual(layer.backgroundColor, palette.nsColor(.userBubble).cgColor,
                          "this theme's surface and user bubble agree, so this proves nothing")
        XCTAssertNotEqual(layer.borderColor, palette.nsColor(.userBubbleBorder).cgColor)
    }

    func testV008_terminalAssistantMatchesTerminalUser() throws {
        let user = try XCTUnwrap(bubble(role: .user, style: .terminal).layer)
        let assistant = try XCTUnwrap(bubble(role: .assistant, style: .terminal).layer)
        XCTAssertEqual(assistant.backgroundColor, user.backgroundColor)
        XCTAssertEqual(assistant.borderColor, user.borderColor)
        XCTAssertEqual(assistant.borderWidth, user.borderWidth)
        XCTAssertEqual(assistant.backgroundColor, palette.nsColor(.surface).cgColor)
    }

    // MARK: - Work output

    func testV009_workOutputIsSecondaryTextInSpeakerStyle() throws {
        let made = bubble(role: .assistant, style: .speaker, isWorkOutput: true)
        XCTAssertEqual(try textColor(of: made), palette.nsColor(.secondaryText))
        XCTAssertNotEqual(try textColor(of: made), palette.nsColor(.personaText))
    }

    func testV010_workOutputIsSecondaryTextInTerminalStyle() throws {
        let made = bubble(role: .assistant, style: .terminal, isWorkOutput: true)
        XCTAssertEqual(try textColor(of: made), palette.nsColor(.secondaryText))
        XCTAssertNotEqual(try textColor(of: made), palette.primaryTextColor)
    }

    func testV011_workOutputHasNoEffectOnUser() throws {
        let made = bubble(role: .user, isWorkOutput: true)
        XCTAssertEqual(try textColor(of: made), palette.nsColor(.userText))
    }

    // MARK: - Borders

    func testV012_aDeclaredPersonaBorderRendersAtOnePoint() throws {
        let color = try XCTUnwrap(RGBAColor(hexString: "#ff8800ff"))
        useTheme(customTheme(roles: [.personaBubbleBorder: color]))
        let layer = try XCTUnwrap(bubble(role: .assistant).layer)
        XCTAssertEqual(layer.borderWidth, 1)
        XCTAssertEqual(layer.borderColor, palette.nsColor(.personaBubbleBorder).cgColor)
    }

    func testV013_anUndeclaredPersonaBorderDoesNotRender() throws {
        XCTAssertFalse(palette.declares(.personaBubbleBorder), "this theme declares the border")
        let layer = try XCTUnwrap(bubble(role: .assistant).layer)
        XCTAssertEqual(layer.borderWidth, 0)
        XCTAssertNil(layer.borderColor)
    }

    func testV014_anErrorBubbleAlwaysHasADangerBorder() throws {
        for theme in [BuiltInThemes.dracula, BuiltInThemes.nord, customTheme()] {
            useTheme(theme)
            let layer = try XCTUnwrap(bubble(role: .error).layer)
            XCTAssertEqual(layer.borderWidth, 1, "\(theme.name)")
            XCTAssertEqual(layer.borderColor, palette.nsColor(.danger).cgColor, "\(theme.name)")
        }
    }

    func testV015_aNoticeNeverHasABorder() throws {
        let layer = try XCTUnwrap(bubble(role: .notice).layer)
        XCTAssertEqual(layer.borderWidth, 0)
        XCTAssertNil(layer.borderColor)
    }

    // MARK: - Fonts and timestamp

    private func resetTerminalFont() {
        UserSettings.terminalFontName.value = UserSettings.terminalFontName.defaultValue
        UserSettings.terminalFontSize.value = UserSettings.terminalFontSize.defaultValue
    }

    func testV016_textAndTimestampAreSetInMenloNotTheThemesBodyFont() throws {
        resetTerminalFont()
        let made = bubble(text: "hello there", showsInlineTimestamp: true)
        let body = try font(at: 0, in: made)
        let time = try font(at: ("hello there" as NSString).length + 2, in: made)
        XCTAssertEqual(body.fontName, "Menlo-Regular")
        XCTAssertEqual(body.pointSize, 13, accuracy: 0.01)
        XCTAssertEqual(time.fontName, "Menlo-Regular")
        XCTAssertEqual(time.pointSize, 11, accuracy: 0.01)
        XCTAssertNotEqual(body.fontName, palette.font(.body).fontName, "the theme's body font is Menlo too")
    }

    private func september23(hour: Int, minute: Int) throws -> Date {
        let day = DateComponents(year: 2026, month: 9, day: 23, hour: hour, minute: minute)
        return try XCTUnwrap(Calendar.current.date(from: day))
    }

    func testV017_morningTimestampHasAnUnpaddedHour() throws {
        let date = try september23(hour: 9, minute: 5)
        let made = bubble(text: "hi", timestamp: date, showsInlineTimestamp: true)
        XCTAssertEqual(try shownText(of: made), "hi  9:05 \(DateFormatter().amSymbol ?? "AM")")
    }

    func testV018_afternoonTimestampReadsTwoThirty() throws {
        let date = try september23(hour: 14, minute: 30)
        let made = bubble(text: "hi", timestamp: date, showsInlineTimestamp: true)
        XCTAssertEqual(try shownText(of: made), "hi  2:30 \(DateFormatter().pmSymbol ?? "PM")")
    }

    func testV019_noTimestampWhenInlineTimestampIsOff() throws {
        let date = try september23(hour: 9, minute: 5)
        let made = bubble(text: "hi", timestamp: date, showsInlineTimestamp: false)
        XCTAssertEqual(try shownText(of: made), "hi")
    }

    func testV020_timestampIsElevenPointsAtThirteenPointText() throws {
        resetTerminalFont()
        XCTAssertEqual(palette.size(.caption), 11)
        XCTAssertEqual(palette.size(.body), 13)
        XCTAssertEqual(AIChatBubbleView.timestampFont(for: palette).pointSize, 11, accuracy: 0.0001)
        let made = bubble(text: "hi", showsInlineTimestamp: true)
        XCTAssertEqual(try font(at: 0, in: made).pointSize, 13, accuracy: 0.0001)
        XCTAssertEqual(try font(at: 4, in: made).pointSize, 11, accuracy: 0.0001)
    }

    func testV021_aZeroBodySizeLeavesTheTimestampInTheMessageFont() throws {
        var typography = ThemeTypography.system
        typography.styles[TextRole.body.rawValue] = FontStyle(size: 0)
        useTheme(customTheme(typography: typography))
        XCTAssertEqual(palette.size(.body), 0)
        XCTAssertEqual(AIChatBubbleView.timestampFont(for: palette), AIChatBubbleView.bodyFont(for: palette))

        let made = bubble(text: "hi", showsInlineTimestamp: true)
        XCTAssertEqual(try font(at: 4, in: made), try font(at: 0, in: made))
    }

    func testV022_timestampColorIsTimestampTextForEveryRole() throws {
        for role in [ChatMessage.Role.user, .assistant, .error, .notice] {
            let made = bubble(role: role, text: "hi", showsInlineTimestamp: true)
            let stamp = try XCTUnwrap(attribute(.foregroundColor, at: 4, in: made) as? NSColor)
            XCTAssertEqual(stamp, palette.nsColor(.timestampText), "\(role)")
            XCTAssertNotEqual(stamp, try textColor(of: made), "\(role): the timestamp took the text's color")
        }
    }
}
