import Testing
import UIKit
import AgenticDeveloperHubSDK
@testable import AgenticDeveloperHubSDKUI

@MainActor
@Suite("MobileThinkingIndicatorView")
struct MobileThinkingIndicatorViewTests {

    private func makeManager(activeThemeID: String) -> ThemeManager {
        ThemeManager(storage: InMemoryThemeStorage(activeThemeID: activeThemeID), appearanceDriver: nil)
    }

    @Test("constructs, lays out, and can start/stop animating without crashing")
    func constructsAndAnimates() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let indicator = MobileThinkingIndicatorView()
        indicator.frame = CGRect(x: 0, y: 0, width: 48, height: 28)
        indicator.layoutIfNeeded()
        indicator.startAnimating()
        indicator.stopAnimating()
        #expect(indicator.frame.width == 48)
    }

    /// The indicator's own ink follows the theme — but its *fill* does not,
    /// because it has none. Web's `.pc-typing` declares no `background`, so
    /// the surface belongs to the chat view alone; painting `chatSurface`
    /// here too stacked a second copy of it, which a translucent theme shows
    /// as a lighter band hovering over the composer. So the assertion is
    /// deliberately two-sided: the dots repaint, the fill stays clear.
    @Test("repaints its ink when the active theme changes, and never its fill")
    func repaintsOnThemeChange() throws {
        let manager = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let indicator = MobileThinkingIndicatorView()
        indicator.frame = CGRect(x: 0, y: 0, width: 48, height: 28)
        indicator.layoutIfNeeded()

        func dotColor() throws -> UIColor? {
            let stack = try #require(indicator.subviews.compactMap { $0 as? UIStackView }.first)
            return stack.arrangedSubviews.first?.backgroundColor
        }

        let before = try dotColor()
        manager.selectTheme(id: BuiltInThemes.dracula.id)

        #expect(before != nil)
        #expect(before != (try dotColor()))
        #expect(indicator.backgroundColor == .clear)
    }

    // MARK: Words-empty fallback (ci-thinking-dots-fallback)

    @Test("with no vocabulary configured, update(status:) drives only the dot pulse and never runs a phase machine")
    func fallsBackToDotsWhenWordsIsEmpty() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let indicator = MobileThinkingIndicatorView()

        // Default configuration: words is empty.
        #expect(indicator.currentPhase == nil)

        indicator.update(status: ChatStatus(kind: .think))
        // Still nil — a non-nil status never engages ThinkingPhase.Machine
        // while no vocabulary is configured.
        #expect(indicator.currentPhase == nil)
        #expect(indicator.label.isHidden)

        indicator.update(status: nil)
        #expect(indicator.currentPhase == nil)
    }

    // MARK: Phase-driven line (vocabulary configured)

    @Test("shows a configured word while thinking, then settles to a frozen 'thought for Ns' line")
    func showsWordThenSettles() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let indicator = MobileThinkingIndicatorView()
        var configuration = MobileThinkingIndicatorConfiguration()
        configuration.words = [ChatStatusWordPair(present: "zeeping", past: "zeeped")]
        indicator.configure(configuration)

        indicator.update(status: ChatStatus(kind: .think))
        #expect(indicator.currentPhase == .thinking)
        #expect(indicator.label.text?.contains("zeeping") == true)
        #expect(!indicator.label.isHidden)

        indicator.update(status: nil)
        #expect(indicator.currentPhase == .done)
        #expect(indicator.label.text?.contains("zeeped") == true)
        #expect(indicator.label.text?.contains("for") == true)
    }

    @Test("repaints the phase-driven line's colours when the active theme changes")
    func repaintsPhaseLineOnThemeChange() {
        let manager = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let indicator = MobileThinkingIndicatorView()
        var configuration = MobileThinkingIndicatorConfiguration()
        configuration.words = [ChatStatusWordPair(present: "zeeping", past: "zeeped")]
        indicator.configure(configuration)
        indicator.update(status: ChatStatus(kind: .think))
        indicator.update(status: nil) // settles to .done — colours come from .thinkingDoneText

        func renderedColor() -> UIColor? {
            guard let attributed = indicator.label.attributedText, attributed.length > 0 else { return nil }
            return attributed.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor
        }

        let before = renderedColor()
        manager.selectTheme(id: BuiltInThemes.dracula.id)
        let after = renderedColor()

        #expect(before != nil)
        #expect(before != after)
    }
}
