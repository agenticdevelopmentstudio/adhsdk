import Testing
import Foundation
import AgenticDeveloperHubSDK
@testable import AgenticDeveloperHubSDKUI

/// The theme binding, on iOS. `Themeable`, `ThemePaletteObserver` and
/// `ThemeManager`'s core are platform-neutral; this bundle is what proves it —
/// the macOS suite would keep passing if any of them quietly re-acquired an
/// AppKit dependency.
///
/// Serialized because `ThemeManager.shared` is process-wide: a manager alive in
/// one test would otherwise be visible to a concurrently running one.
@MainActor
@Suite("Theme binding (iOS)", .serialized)
struct ThemeBindingTests {

    /// A `ThemeAppearanceDriver` that records what it was asked to apply, so a
    /// test can assert the seam is driven without any platform chrome.
    private final class RecordingDriver: ThemeAppearanceDriver {
        var applied: [(theme: ColorTheme, palette: SemanticPalette)] = []
        func apply(_ theme: ColorTheme, palette: SemanticPalette) {
            applied.append((theme, palette))
        }
    }

    @Test("the observer's closure runs immediately on creation")
    func appliesImmediately() {
        var applied: SemanticPalette?
        let observer = ThemePaletteObserver { applied = $0 }
        #expect(applied != nil)
        withExtendedLifetime(observer) {}
    }

    @Test("with no ThemeManager, the observer falls back to Solarized Dark")
    func fallsBackToSolarizedDark() {
        #expect(ThemeManager.shared == nil)
        var applied: SemanticPalette?
        let observer = ThemePaletteObserver { applied = $0 }
        #expect(applied?.theme == BuiltInThemes.solarizedDark)
        #expect(ThemePaletteObserver.currentPalette.theme == BuiltInThemes.solarizedDark)
        withExtendedLifetime(observer) {}
    }

    @Test("with a live ThemeManager, the observer reads that manager's palette")
    func readsLiveManagerPalette() {
        let manager = ThemeManager(
            storage: InMemoryThemeStorage(activeThemeID: BuiltInThemes.dracula.id),
            appearanceDriver: nil
        )
        var applied: SemanticPalette?
        let observer = ThemePaletteObserver { applied = $0 }
        #expect(applied?.theme == BuiltInThemes.dracula)
        withExtendedLifetime((manager, observer)) {}
    }

    @Test("a theme change repaints every live observer")
    func repaintsOnChange() {
        let manager = ThemeManager(
            storage: InMemoryThemeStorage(activeThemeID: BuiltInThemes.solarizedDark.id),
            appearanceDriver: nil
        )
        var applied: [ColorTheme] = []
        let observer = ThemePaletteObserver { applied.append($0.theme) }
        #expect(applied == [BuiltInThemes.solarizedDark])

        manager.selectTheme(id: BuiltInThemes.dracula.id)
        // The observer delivers on `RunLoop.main`, so pump it.
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))

        #expect(applied == [BuiltInThemes.solarizedDark, BuiltInThemes.dracula])
        withExtendedLifetime((manager, observer)) {}
    }

    @Test("ThemeManager drives an injected appearance driver at init and on change")
    func drivesTheInjectedDriver() {
        let driver = RecordingDriver()
        let manager = ThemeManager(
            storage: InMemoryThemeStorage(activeThemeID: BuiltInThemes.solarizedDark.id),
            appearanceDriver: driver
        )
        #expect(driver.applied.count == 1)
        #expect(driver.applied.first?.theme == BuiltInThemes.solarizedDark)

        manager.selectTheme(id: BuiltInThemes.nord.id)
        #expect(driver.applied.count == 2)
        #expect(driver.applied.last?.theme == BuiltInThemes.nord)
        #expect(driver.applied.last?.palette.theme == BuiltInThemes.nord)
        withExtendedLifetime(manager) {}
    }

    @Test("a Themeable conformer needs no platform import")
    func themeableIsPlatformNeutral() {
        final class Swatch: Themeable {
            var painted: SemanticPalette?
            func applyTheme(_ palette: SemanticPalette) { painted = palette }
        }
        let swatch = Swatch()
        swatch.applyTheme(SemanticPalette(theme: BuiltInThemes.nord))
        #expect(swatch.painted?.theme == BuiltInThemes.nord)
    }
}
