import Testing
import AppKit
import AgenticDeveloperHubSDK
@testable import AgenticDeveloperHubSDKUI

@MainActor
@Suite("ThinkingIndicatorView")
struct ThinkingIndicatorViewTests {

    private func makeManager(activeThemeID: String) -> ThemeManager {
        ThemeManager(storage: InMemoryThemeStorage(activeThemeID: activeThemeID))
    }

    @Test("constructs, lays out, and can start/stop animating without crashing")
    func constructsAndAnimates() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let indicator = ThinkingIndicatorView()
        indicator.frame = NSRect(x: 0, y: 0, width: 48, height: 28)
        indicator.layoutSubtreeIfNeeded()
        indicator.startAnimating()
        indicator.stopAnimating()
        #expect(indicator.frame.width == 48)
    }

    /// The indicator's own ink follows the theme — but its *fill* does not,
    /// because it has none. Web's `.pc-typing` declares no `background`, so
    /// the surface belongs to the chat view alone; painting `chatSurface`
    /// here too stacked a second copy of it, which a translucent theme shows
    /// as a lighter rounded band hovering over the composer. So the assertion
    /// is deliberately two-sided: the dots repaint, the fill stays clear.
    @Test("repaints its ink when the active theme changes, and never its fill")
    func repaintsOnThemeChange() throws {
        let manager = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let indicator = ThinkingIndicatorView()
        indicator.frame = NSRect(x: 0, y: 0, width: 48, height: 28)
        indicator.layoutSubtreeIfNeeded()

        func dotColor() throws -> CGColor? {
            let stack = try #require(indicator.subviews.compactMap { $0 as? NSStackView }.first)
            return stack.arrangedSubviews.first?.layer?.backgroundColor
        }

        let before = try dotColor()
        manager.selectTheme(id: BuiltInThemes.dracula.id)

        #expect(before != nil)
        #expect(before != (try dotColor()))
        #expect(indicator.layer?.backgroundColor == NSColor.clear.cgColor)
    }

    // MARK: Words-empty fallback (ci-thinking-dots-fallback)

    @Test("with no vocabulary configured, update(status:) drives only the dot pulse and never runs a phase machine")
    func fallsBackToDotsWhenWordsIsEmpty() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let indicator = ThinkingIndicatorView()

        // Default configuration: words is empty.
        #expect(indicator.currentPhase == nil)

        indicator.update(status: ChatStatus(kind: .think))
        // Still nil — a non-nil status never engages ThinkingPhase.Machine
        // while no vocabulary is configured. If this wiring were removed
        // (e.g. `update(status:)` always built a Machine regardless of
        // `configuration.words`), this would flip to `.thinking` and fail.
        #expect(indicator.currentPhase == nil)
        #expect(indicator.label.isHidden)

        indicator.update(status: nil)
        #expect(indicator.currentPhase == nil)
    }

    // MARK: Phase-driven line (vocabulary configured)

    @Test("shows a configured word while thinking, then settles to a frozen 'thought for Ns' line")
    func showsWordThenSettles() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let indicator = ThinkingIndicatorView()
        var configuration = ThinkingIndicatorConfiguration()
        configuration.words = [ChatStatusWordPair(present: "zeeping", past: "zeeped")]
        indicator.configure(configuration)

        // Fails if `configure(_:)`/`update(status:)` stop wiring the
        // ShuffleBag and ThinkingPhase.Machine into the label.
        indicator.update(status: ChatStatus(kind: .think))
        #expect(indicator.currentPhase == .thinking)
        #expect(indicator.label.stringValue.contains("zeeping"))
        #expect(!indicator.label.isHidden)

        indicator.update(status: nil)
        #expect(indicator.currentPhase == .done)
        #expect(indicator.label.stringValue.contains("zeeped"))
        #expect(indicator.label.stringValue.contains("for"))
    }

    @Test("repaints the phase-driven line's colours when the active theme changes")
    func repaintsPhaseLineOnThemeChange() {
        let manager = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let indicator = ThinkingIndicatorView()
        var configuration = ThinkingIndicatorConfiguration()
        configuration.words = [ChatStatusWordPair(present: "zeeping", past: "zeeped")]
        indicator.configure(configuration)
        indicator.update(status: ChatStatus(kind: .think))
        indicator.update(status: nil) // settles to .done — colours come from .thinkingDoneText

        func renderedColor() -> NSColor? {
            let attributed = indicator.label.attributedStringValue
            guard attributed.length > 0 else { return nil }
            return attributed.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? NSColor
        }

        let before = renderedColor()
        manager.selectTheme(id: BuiltInThemes.dracula.id)
        let after = renderedColor()

        // Fails if the label stops being repainted on `ThemeManager`'s
        // notification — exactly the class of bug ci-reactivity-is-behaviour
        // calls out: a green build with the wiring silently dropped.
        #expect(before != nil)
        #expect(before != after)
    }

    // MARK: The glyph's box

    /// Web puts the glyph in `flex: 0 0 1.6ch; text-align: center` precisely so
    /// "a wider frame fattens symmetrically from the center instead of shoving
    /// the word sideways". This is that, in AppKit: the words start in the same
    /// place no matter which glyph is up.
    @Test("the glyph's box does not move when the glyph does")
    func glyphBoxHoldsItsWidth() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let indicator = ThinkingIndicatorView()
        var configuration = ThinkingIndicatorConfiguration()
        configuration.words = [ChatStatusWordPair(present: "zeeping", past: "zeeped")]
        // Two frames of deliberately different widths, plus a done glyph of a
        // third. Concatenated into one run these would each shift the words.
        configuration.frames = ["i", "MMMM"]
        configuration.doneGlyph = "WW"
        indicator.configure(configuration)
        indicator.frame = NSRect(x: 0, y: 0, width: 320, height: 28)

        func wordsOrigin() -> CGFloat {
            indicator.layoutSubtreeIfNeeded()
            return indicator.label.frame.minX
        }

        indicator.update(status: ChatStatus(kind: .think))
        let thinking = wordsOrigin()
        #expect(indicator.glyphLabel.stringValue.isEmpty == false)

        indicator.update(status: nil) // settles, swapping in the done glyph
        #expect(wordsOrigin() == thinking)
        #expect(indicator.glyphLabel.stringValue == "WW")

        // And the box is wide enough for the widest of them, so nothing is
        // truncated into the ellipsis AppKit would otherwise draw.
        let font = ThemePaletteObserver.currentPalette.font(.caption)
        let widest = ("MMMM" as NSString).size(withAttributes: [.font: font]).width
        #expect(indicator.glyphLabel.frame.width >= widest)
    }

    @Test("the glyph and the words are separately inked, so a tint can name one")
    func tintReachesOnlyTheGlyph() throws {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let indicator = ThinkingIndicatorView()
        var configuration = ThinkingIndicatorConfiguration()
        configuration.words = [ChatStatusWordPair(present: "zeeping", past: "zeeped")]
        configuration.tint = ThinkingTint(
            color: RGBAColor(hexString: "#ff00ffff")!, applies: .icons)
        indicator.configure(configuration)
        indicator.update(status: ChatStatus(kind: .think))

        func ink(_ field: NSTextField) -> NSColor? {
            let attributed = field.attributedStringValue
            guard attributed.length > 0 else { return nil }
            return attributed.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? NSColor
        }
        let glyphInk = try #require(ink(indicator.glyphLabel))
        let wordInk = try #require(ink(indicator.label))
        // Splitting the line into two labels must not have flattened the two
        // spans onto one colour.
        #expect(glyphInk != wordInk)
        #expect(glyphInk == NSColor(RGBAColor(hexString: "#ff00ffff")!))
    }

    // MARK: The resting line

    private func makeIdleIndicator() -> ThinkingIndicatorView {
        let indicator = ThinkingIndicatorView()
        var configuration = ThinkingIndicatorConfiguration()
        configuration.words = [ChatStatusWordPair(present: "zeeping", past: "zeeped")]
        configuration.idlePhrase = "waiting to zeeble"
        indicator.configure(configuration)
        return indicator
    }

    private func renderedColor(_ indicator: ThinkingIndicatorView) -> NSColor? {
        let attributed = indicator.label.attributedStringValue
        guard attributed.length > 0 else { return nil }
        return attributed.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? NSColor
    }

    @Test("before anything has run, the line shows the idle phrase in the idle ink")
    func idleLineUsesTheIdleInk() throws {
        let manager = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let indicator = makeIdleIndicator()

        #expect(indicator.currentPhase == .idle)
        #expect(indicator.label.stringValue.contains("waiting to zeeble"))
        let color = try #require(renderedColor(indicator))
        #expect(color == manager.currentPalette.nsColor(.thinkingIdleText))
        withExtendedLifetime(manager) {}
    }

    /// The two settled lines are the same shape — a glyph, then a phrase — and
    /// mean opposite things: one reports work that happened, the other reports
    /// that none has. Only the colour tells them apart, so a derivation that
    /// collapsed the two roles would make the status line lie silently.
    @Test("the resting line and the settled line are not the same colour")
    func idleInkDiffersFromDoneInk() throws {
        let manager = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let indicator = makeIdleIndicator()
        let idle = try #require(renderedColor(indicator))

        indicator.update(status: ChatStatus(kind: .think))
        indicator.update(status: nil)
        #expect(indicator.currentPhase == .done)
        let done = try #require(renderedColor(indicator))

        #expect(idle != done)
        #expect(done == manager.currentPalette.nsColor(.thinkingDoneText))
        withExtendedLifetime(manager) {}
    }

    @Test("with no idle phrase configured, the resting line is simply empty")
    func noIdlePhraseLeavesTheLineBlank() {
        let manager = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let indicator = ThinkingIndicatorView()
        var configuration = ThinkingIndicatorConfiguration()
        configuration.words = [ChatStatusWordPair(present: "zeeping", past: "zeeped")]
        indicator.configure(configuration)
        #expect(indicator.label.stringValue.isEmpty)
        withExtendedLifetime(manager) {}
    }

    @Test("colorful's hue draws never land in the excluded green band")
    func colorfulHueSkipsGreen() {
        for _ in 0..<500 {
            let hue = randomNonGreenHue()
            #expect(hue < 75 || hue >= 165, "hue \(hue) is in the excluded green band")
        }
    }
}
