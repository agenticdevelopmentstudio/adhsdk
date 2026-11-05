import Testing
import AppKit
import Foundation
import AgenticDeveloperHubSDK
@testable import AgenticDeveloperHubSDKUI

@MainActor
@Suite("MessageBubbleView")
struct MessageBubbleViewTests {

    private func makeManager(activeThemeID: String) -> ThemeManager {
        ThemeManager(storage: InMemoryThemeStorage(activeThemeID: activeThemeID))
    }

    @Test("constructs and lays out without crashing, sized to the given maxWidth")
    func constructsAndLaysOut() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let message = FixtureMessage(id: "1", localID: "1", senderID: "persona-1", text: "hello world", timestamp: Date())
        let bubble = MessageBubbleView(message: message, maxWidth: 300, isLocalUser: false)
        bubble.frame = NSRect(x: 0, y: 0, width: 300, height: 80)
        bubble.layoutSubtreeIfNeeded()
        #expect(bubble.frame.width <= 300)
        #expect(bubble.message.text == "hello world")
        #expect(bubble.isLocalUser == false)
    }

    @Test("repaints its layer background when the active theme changes")
    func repaintsOnThemeChange() {
        let manager = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let message = FixtureMessage(id: "1", localID: "1", senderID: "persona-1", text: "hi", timestamp: Date())
        let bubble = MessageBubbleView(message: message, maxWidth: 300, isLocalUser: false)

        let before = bubble.layer?.backgroundColor
        manager.selectTheme(id: BuiltInThemes.dracula.id)
        let after = bubble.layer?.backgroundColor

        #expect(before != nil)
        #expect(before != after)
    }

    @Test("local-user and persona bubbles resolve to different bubble colors")
    func localUserAndPersonaDifferInColor() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let message = FixtureMessage(id: "1", localID: "1", senderID: "x", text: "hi", timestamp: Date())
        let userBubble = MessageBubbleView(message: message, maxWidth: 300, isLocalUser: true)
        let personaBubble = MessageBubbleView(message: message, maxWidth: 300, isLocalUser: false)
        #expect(userBubble.layer?.backgroundColor != personaBubble.layer?.backgroundColor)
    }

    // MARK: Markdown

    @Test("renders the message text as markdown: a code span takes the code font")
    func rendersMessageTextAsMarkdown() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let palette = ThemePaletteObserver.currentPalette
        let message = FixtureMessage(
            id: "1", localID: "1", senderID: "persona-1", text: "run `ls` now", timestamp: nil)
        let bubble = MessageBubbleView(message: message, maxWidth: 300, isLocalUser: false)

        let rendered = bubble.renderedText
        #expect(rendered.string == "run ls now")
        let location = (rendered.string as NSString).range(of: "ls").location
        #expect(rendered.attributes(at: location, effectiveRange: nil)[.font] as? NSFont == palette.font(.code))
    }

    // MARK: Delivery status

    @Test("a failed message borders the bubble in danger and appends its reason")
    func failedMessageBordersAndAppendsReason() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let palette = ThemePaletteObserver.currentPalette
        let message = FixtureMessage(
            id: nil, localID: "1", senderID: "user-1", text: "hi", timestamp: nil,
            deliveryStatus: .failed(reason: "network unreachable"))
        let bubble = MessageBubbleView(message: message, maxWidth: 300, isLocalUser: true)

        #expect(bubble.renderedText.string.contains("network unreachable"))
        #expect((bubble.layer?.borderWidth ?? 0) > 0)
        #expect(bubble.layer?.borderColor == palette.nsColor(.danger).cgColor)
    }

    @Test("the failure reason is styled in the caption font and the danger color")
    func failureReasonIsStyledDanger() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let palette = ThemePaletteObserver.currentPalette
        let message = FixtureMessage(
            id: nil, localID: "1", senderID: "user-1", text: "hi", timestamp: nil,
            deliveryStatus: .failed(reason: "boom"))
        let bubble = MessageBubbleView(message: message, maxWidth: 300, isLocalUser: true)

        let rendered = bubble.renderedText
        let reasonRange = (rendered.string as NSString).range(of: "boom")
        #expect(reasonRange.location != NSNotFound)
        let attributes = rendered.attributes(at: reasonRange.location, effectiveRange: nil)
        #expect(attributes[.font] as? NSFont == palette.font(.caption))
        #expect(attributes[.foregroundColor] as? NSColor == palette.nsColor(.danger))
    }

    // MARK: Bubble outline

    /// Solarized Dark declares no `personaBubbleBorder`, and on the website a
    /// theme that declares none draws none — every role still *derives* an
    /// opaque colour, so the outline has to follow what the theme said, not
    /// what its palette resolves to.
    @Test("a delivered message has no border and no failure text")
    func deliveredMessageHasNoBorder() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let message = FixtureMessage(
            id: "1", localID: "1", senderID: "user-1", text: "hi", timestamp: nil,
            deliveryStatus: .delivered)
        let bubble = MessageBubbleView(message: message, maxWidth: 300, isLocalUser: true)

        #expect((bubble.layer?.borderWidth ?? 0) == 0)
        #expect(bubble.renderedText.string == "hi")
    }

    /// The other half of that rule: `techy` ports web's
    /// `--pc-persona-border: rgba(0, 255, 136, 0.3)`, so its persona bubbles
    /// are outlined in exactly that colour.
    @Test("a theme that declares a bubble border draws it in that color")
    func declaredBubbleBorderIsDrawn() throws {
        // By name rather than by symbol: the web-ported themes are
        // `internal` on `BuiltInThemes`, and `all` is the public way in.
        let techy = try #require(BuiltInThemes.all.first { $0.name == "Techy" })
        // Held, not discarded: `ThemeManager.shared` is weak, so a manager
        // nobody retains is gone before the bubble asks for its palette and
        // the view falls back to the Solarized Dark default.
        let manager = makeManager(activeThemeID: techy.id)
        let palette = manager.currentPalette
        let message = FixtureMessage(
            id: "1", localID: "1", senderID: "persona-1", text: "hi", timestamp: nil,
            deliveryStatus: .received)
        let bubble = MessageBubbleView(message: message, maxWidth: 300, isLocalUser: false)

        #expect(palette.declares(.personaBubbleBorder))
        #expect(bubble.layer?.borderWidth == 1)
        #expect(bubble.layer?.borderColor == palette.nsColor(.personaBubbleBorder).cgColor)
        withExtendedLifetime(manager) {}
    }

    @Test("a composing message appends a streaming caret in the persona-name color")
    func composingMessageAppendsCaret() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let palette = ThemePaletteObserver.currentPalette
        let message = FixtureMessage(
            id: nil, localID: "d", senderID: "persona-1", text: "streaming", timestamp: nil,
            deliveryStatus: .composing)
        let bubble = MessageBubbleView(message: message, maxWidth: 300, isLocalUser: false)

        let rendered = bubble.renderedText
        #expect(rendered.string.hasSuffix(MessageBubbleView.streamingCaret))
        let caretLocation = rendered.length - (MessageBubbleView.streamingCaret as NSString).length
        let attributes = rendered.attributes(at: caretLocation, effectiveRange: nil)
        #expect(attributes[.foregroundColor] as? NSColor == palette.nsColor(.personaName))
    }

    // MARK: Timestamp

    /// Web renders `.pc-time` as a `display: block` element under the message
    /// text — the bubble's last child — not as a suffix on the sentence. The
    /// old rendering appended `"  08:05"` into the same run as the text, which
    /// reads as something the persona said.
    @Test("the timestamp is the last thing rendered, on a line of its own")
    func timestampIsOnItsOwnFinalLine() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let message = FixtureMessage(
            id: "1", localID: "1", senderID: "persona-1", text: "hello", timestamp: Date())
        let bubble = MessageBubbleView(message: message, maxWidth: 300, isLocalUser: false)

        let lines = bubble.renderedText.string.components(separatedBy: "\n")
        #expect(lines.count == 2)
        #expect(lines[0] == "hello")
        // Two digits, a separator, two digits — the locale decides the rest.
        #expect(lines[1].range(of: #"^\d{2}\D\d{2}"#, options: .regularExpression) != nil)
    }

    /// `text-align: right` on a user bubble's `.pc-time`, `left` on a
    /// persona's — the clock hugs the side the message is on.
    @Test("the timestamp line is aligned to the sender's side")
    func timestampAlignsToSender() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let message = FixtureMessage(
            id: "1", localID: "1", senderID: "x", text: "hello", timestamp: Date())

        func alignment(isLocalUser: Bool) -> NSTextAlignment? {
            let rendered = MessageBubbleView(
                message: message, maxWidth: 300, isLocalUser: isLocalUser).renderedText
            let location = (rendered.string as NSString).range(of: "\n").location + 1
            let style = rendered.attribute(.paragraphStyle, at: location, effectiveRange: nil)
            return (style as? NSParagraphStyle)?.alignment
        }

        #expect(alignment(isLocalUser: true) == .right)
        #expect(alignment(isLocalUser: false) == .left)
    }

    /// The failure caption is part of the message's story and the clock is a
    /// note about it, so the clock stays last even when both are present.
    @Test("a failed message still ends with its timestamp")
    func failedMessageStillEndsWithTimestamp() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let message = FixtureMessage(
            id: nil, localID: "1", senderID: "user-1", text: "hi", timestamp: Date(),
            deliveryStatus: .failed(reason: "boom"))
        let bubble = MessageBubbleView(message: message, maxWidth: 300, isLocalUser: true)

        let lines = bubble.renderedText.string.components(separatedBy: "\n")
        #expect(lines.count == 3)
        #expect(lines[1] == "boom")
        #expect(lines[2].contains(":") || lines[2].contains("."))
    }

    @Test("a settled message carries no caret")
    func settledMessageHasNoCaret() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let message = FixtureMessage(
            id: "1", localID: "1", senderID: "persona-1", text: "done", timestamp: nil,
            deliveryStatus: .received)
        let bubble = MessageBubbleView(message: message, maxWidth: 300, isLocalUser: false)
        #expect(!bubble.renderedText.string.contains(MessageBubbleView.streamingCaret))
    }
}
