import Testing
import Foundation
import UIKit
import AgenticDeveloperHubSDK
@testable import AgenticDeveloperHubSDKUI

/// The UIKit half of theming, the mirror of `AppKitAppearanceDriverTests`.
///
/// A unit test has no connected window scene, so what is verified here is the
/// decision the driver makes — which `UIUserInterfaceStyle` a theme resolves to
/// — rather than the windows it then writes it onto. That is the part with a
/// rule in it; the loop over `connectedScenes` has none.
@MainActor
@Suite("UIKitAppearanceDriver", .serialized)
struct UIKitAppearanceDriverTests {

    private func palette(_ theme: ColorTheme) -> SemanticPalette { SemanticPalette(theme: theme) }

    @Test("the iOS initializer installs the UIKit driver by default")
    func installsUIKitDriverByDefault() {
        let manager = ThemeManager(storage: InMemoryThemeStorage())
        #expect(manager.appearanceDriver is UIKitAppearanceDriver)
        withExtendedLifetime(manager) {}
    }

    @Test("a light theme resolves to .light whatever the host's preference says")
    func lightThemeWinsOverAutoAppearance() {
        let driver = UIKitAppearanceDriver { .dark }
        let theme = BuiltInThemes.githubLight
        #expect(theme.appearance == .light)
        // Nothing to read off a window here, so the decision is checked
        // directly: the host's answer is not consulted for a pinned theme.
        #expect(driver.resolvedStyle(for: theme) == .light)
    }

    @Test("a dark theme resolves to .dark whatever the host's preference says")
    func darkThemeWinsOverAutoAppearance() {
        let driver = UIKitAppearanceDriver { .light }
        let theme = BuiltInThemes.solarizedDark
        #expect(theme.appearance == .dark)
        #expect(driver.resolvedStyle(for: theme) == .dark)
    }

    @Test("an auto theme defers to the host's preference")
    func autoThemeAsksTheHost() {
        var answer = UIUserInterfaceStyle.light
        let driver = UIKitAppearanceDriver { answer }
        var theme = BuiltInThemes.githubLight
        theme.appearance = .auto

        #expect(driver.resolvedStyle(for: theme) == .light)
        answer = .dark
        #expect(driver.resolvedStyle(for: theme) == .dark)
    }

    @Test("the default host answer is 'whatever the system says'")
    func defaultAutoAppearanceIsUnspecified() {
        var theme = BuiltInThemes.githubLight
        theme.appearance = .auto
        #expect(UIKitAppearanceDriver().resolvedStyle(for: theme) == .unspecified)
    }

    @Test("applying a theme with no connected scenes is a no-op, not a crash")
    func applyWithoutScenesIsHarmless() {
        let driver = UIKitAppearanceDriver()
        driver.apply(BuiltInThemes.solarizedDark, palette: palette(BuiltInThemes.solarizedDark))
    }
}
