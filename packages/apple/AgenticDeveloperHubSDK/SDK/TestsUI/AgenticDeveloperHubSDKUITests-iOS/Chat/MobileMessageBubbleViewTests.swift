import Testing
import UIKit
import Foundation
import AgenticDeveloperHubSDK
@testable import AgenticDeveloperHubSDKUI

@MainActor
@Suite("MobileMessageBubbleView")
struct MobileMessageBubbleViewTests {

    private func makeManager(activeThemeID: String) -> ThemeManager {
        ThemeManager(storage: InMemoryThemeStorage(activeThemeID: activeThemeID), appearanceDriver: nil)
    }

    @Test("constructs and lays out without crashing, sized to the given maxWidth")
    func constructsAndLaysOut() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let message = FixtureMessage(id: "1", localID: "1", senderID: "persona-1", text: "hello world", timestamp: Date())
        let bubble = MobileMessageBubbleView(message: message, maxWidth: 300, isLocalUser: false)
        bubble.frame = CGRect(x: 0, y: 0, width: 300, height: 80)
        bubble.layoutIfNeeded()
        #expect(bubble.frame.width <= 300)
        #expect(bubble.message.text == "hello world")
        #expect(bubble.isLocalUser == false)
    }

    @Test("repaints its background when the active theme changes")
    func repaintsOnThemeChange() {
        let manager = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let message = FixtureMessage(id: "1", localID: "1", senderID: "persona-1", text: "hi", timestamp: Date())
        let bubble = MobileMessageBubbleView(message: message, maxWidth: 300, isLocalUser: false)

        let before = bubble.backgroundColor
        manager.selectTheme(id: BuiltInThemes.dracula.id)
        let after = bubble.backgroundColor

        #expect(before != nil)
        #expect(before != after)
    }

    @Test("local-user and persona bubbles resolve to different bubble colors")
    func localUserAndPersonaDifferInColor() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let message = FixtureMessage(id: "1", localID: "1", senderID: "x", text: "hi", timestamp: Date())
        let userBubble = MobileMessageBubbleView(message: message, maxWidth: 300, isLocalUser: true)
        let personaBubble = MobileMessageBubbleView(message: message, maxWidth: 300, isLocalUser: false)
        #expect(userBubble.backgroundColor != personaBubble.backgroundColor)
    }

    // MARK: Markdown

    @Test("renders the message text as markdown: a code span takes the code font")
    func rendersMessageTextAsMarkdown() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let palette = ThemePaletteObserver.currentPalette
        let message = FixtureMessage(
            id: "1", localID: "1", senderID: "persona-1", text: "run `ls` now", timestamp: nil)
        let bubble = MobileMessageBubbleView(message: message, maxWidth: 300, isLocalUser: false)

        let rendered = bubble.renderedText
        #expect(rendered.string == "run ls now")
        let location = (rendered.string as NSString).range(of: "ls").location
        #expect(rendered.attributes(at: location, effectiveRange: nil)[.font] as? UIFont == palette.font(.code))
    }

    // MARK: Delivery status

    @Test("a failed message borders the bubble in danger and appends its reason")
    func failedMessageBordersAndAppendsReason() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let palette = ThemePaletteObserver.currentPalette
        let message = FixtureMessage(
            id: nil, localID: "1", senderID: "user-1", text: "hi", timestamp: nil,
            deliveryStatus: .failed(reason: "network unreachable"))
        let bubble = MobileMessageBubbleView(message: message, maxWidth: 300, isLocalUser: true)

        #expect(bubble.renderedText.string.contains("network unreachable"))
        #expect(bubble.layer.borderWidth > 0)
        #expect(bubble.layer.borderColor == palette.uiColor(.danger).cgColor)
    }

    @Test("the failure reason is styled in the caption font and the danger color")
    func failureReasonIsStyledDanger() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let palette = ThemePaletteObserver.currentPalette
        let message = FixtureMessage(
            id: nil, localID: "1", senderID: "user-1", text: "hi", timestamp: nil,
            deliveryStatus: .failed(reason: "boom"))
        let bubble = MobileMessageBubbleView(message: message, maxWidth: 300, isLocalUser: true)

        let rendered = bubble.renderedText
        let reasonRange = (rendered.string as NSString).range(of: "boom")
        #expect(reasonRange.location != NSNotFound)
        let attributes = rendered.attributes(at: reasonRange.location, effectiveRange: nil)
        #expect(attributes[.font] as? UIFont == palette.font(.caption))
        #expect(attributes[.foregroundColor] as? UIColor == palette.uiColor(.danger))
    }

    @Test("a delivered message has no border and no failure text")
    func deliveredMessageHasNoBorder() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let message = FixtureMessage(
            id: "1", localID: "1", senderID: "user-1", text: "hi", timestamp: nil,
            deliveryStatus: .delivered)
        let bubble = MobileMessageBubbleView(message: message, maxWidth: 300, isLocalUser: true)

        #expect(bubble.layer.borderWidth == 0)
        #expect(bubble.renderedText.string == "hi")
    }

    @Test("a composing message appends a streaming caret in the persona-name color")
    func composingMessageAppendsCaret() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let palette = ThemePaletteObserver.currentPalette
        let message = FixtureMessage(
            id: nil, localID: "d", senderID: "persona-1", text: "streaming", timestamp: nil,
            deliveryStatus: .composing)
        let bubble = MobileMessageBubbleView(message: message, maxWidth: 300, isLocalUser: false)

        let rendered = bubble.renderedText
        #expect(rendered.string.hasSuffix(MobileMessageBubbleView.streamingCaret))
        let caretLocation = rendered.length - (MobileMessageBubbleView.streamingCaret as NSString).length
        let attributes = rendered.attributes(at: caretLocation, effectiveRange: nil)
        #expect(attributes[.foregroundColor] as? UIColor == palette.uiColor(.personaName))
    }

    @Test("a settled message carries no caret")
    func settledMessageHasNoCaret() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let message = FixtureMessage(
            id: "1", localID: "1", senderID: "persona-1", text: "done", timestamp: nil,
            deliveryStatus: .received)
        let bubble = MobileMessageBubbleView(message: message, maxWidth: 300, isLocalUser: false)
        #expect(!bubble.renderedText.string.contains(MobileMessageBubbleView.streamingCaret))
    }
}
