import Testing
import Foundation
import AppKit
import AgenticDeveloperHubSDK
@testable import AgenticDeveloperHubSDKUI

/// The AppKit half of theming, now that it sits behind `ThemeAppearanceDriver`
/// rather than inside `ThemeManager`. These tests exist to pin that the seam
/// changed nothing: macOS still installs the AppKit driver by default, and
/// `drivesApplicationAppearance = false` still means "don't touch app chrome".
@MainActor
@Suite("AppKitAppearanceDriver", .serialized)
struct AppKitAppearanceDriverTests {

    private func makeManager(activeThemeID: String? = nil) -> ThemeManager {
        ThemeManager(storage: InMemoryThemeStorage(activeThemeID: activeThemeID))
    }

    @Test("the macOS initializer installs the AppKit driver by default")
    func installsAppKitDriverByDefault() {
        let manager = makeManager()
        #expect(manager.drivesApplicationAppearance)
        #expect(manager.appearanceDriver is AppKitAppearanceDriver)
        withExtendedLifetime(manager) {}
    }

    @Test("drivesApplicationAppearance = false uninstalls the driver, true reinstalls it")
    func togglingTheFlagInstallsAndRemovesTheDriver() {
        let manager = makeManager()
        manager.drivesApplicationAppearance = false
        #expect(manager.appearanceDriver == nil)
        #expect(!manager.drivesApplicationAppearance)

        manager.drivesApplicationAppearance = true
        #expect(manager.appearanceDriver is AppKitAppearanceDriver)
        withExtendedLifetime(manager) {}
    }

    @Test("drivesApplicationAppearance = true is a no-op when AppKit already drives")
    func settingTrueTwiceKeepsTheSameDriver() {
        let manager = makeManager()
        let installed = manager.appearanceDriver
        manager.drivesApplicationAppearance = true
        #expect(manager.appearanceDriver === installed)
        withExtendedLifetime(manager) {}
    }

    @Test("a host's own driver survives a write in either direction")
    func aCustomDriverIsNeverClobbered() {
        let custom = RecordingAppearanceDriver()
        let manager = ThemeManager(
            storage: InMemoryThemeStorage(activeThemeID: BuiltInThemes.githubLight.id),
            appearanceDriver: custom
        )
        // The property is about the AppKit driver alone, so a host driver reads
        // false — and neither write may discard it.
        #expect(!manager.drivesApplicationAppearance)

        manager.drivesApplicationAppearance = true
        #expect(manager.appearanceDriver === custom)

        manager.drivesApplicationAppearance = false
        #expect(manager.appearanceDriver === custom)

        // Still wired: the surviving driver is the one that gets applied. The
        // manager applies once at init too, so this is the tail, not the whole
        // list.
        manager.selectTheme(id: BuiltInThemes.solarizedDark.id)
        #expect(custom.appliedThemeIDs.last == BuiltInThemes.solarizedDark.id)
        withExtendedLifetime(manager) {}
    }

    @Test("the driver maps the theme's appearance onto NSApplication")
    func drivesApplicationAppearance() {
        // Must reference NSApplication.shared (not the NSApp implicitly-unwrapped
        // global, which is nil until the host first touches NSApplication.shared)
        // so a host that builds the manager before app setup does not crash.
        let manager = makeManager(activeThemeID: BuiltInThemes.githubLight.id)
        manager.selectTheme(id: BuiltInThemes.solarizedDark.id)
        #expect(NSApplication.shared.appearance?.name == .darkAqua)
        manager.selectTheme(id: BuiltInThemes.githubLight.id)
        #expect(NSApplication.shared.appearance?.name == .aqua)
        withExtendedLifetime(manager) {}
    }

    @Test("with no driver installed, a theme change leaves app chrome alone")
    func noDriverLeavesChromeAlone() {
        let manager = ThemeManager(
            storage: InMemoryThemeStorage(activeThemeID: BuiltInThemes.githubLight.id),
            appearanceDriver: nil
        )
        NSApplication.shared.appearance = NSAppearance(named: .aqua)
        manager.selectTheme(id: BuiltInThemes.solarizedDark.id)
        #expect(NSApplication.shared.appearance?.name == .aqua)
        withExtendedLifetime(manager) {}
    }

    @Test("the shared system pickers are excluded from window-background theming")
    func windowBackgroundFilter() {
        let normal = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: [.titled], backing: .buffered, defer: true
        )
        #expect(ThemeManager.shouldThemeBackground(of: normal))
        #expect(!ThemeManager.shouldThemeBackground(of: NSColorPanel.shared))
        #expect(!ThemeManager.shouldThemeBackground(of: NSFontPanel.shared))
    }

    @Test("the driver repaints a titled window's background to the palette")
    func repaintsWindowBackground() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: [.titled], backing: .buffered, defer: true
        )
        window.orderFront(nil)
        defer { window.orderOut(nil) }

        let theme = BuiltInThemes.dracula
        let palette = SemanticPalette(theme: theme)
        AppKitAppearanceDriver().apply(theme, palette: palette)

        #expect(window.backgroundColor == NSColor(palette.windowBackground))
    }
}

/// A stand-in for a host that supplies its own `ThemeAppearanceDriver` instead
/// of the AppKit one — the case `drivesApplicationAppearance` must not trample.
@MainActor
private final class RecordingAppearanceDriver: ThemeAppearanceDriver {
    private(set) var appliedThemeIDs: [String] = []

    func apply(_ theme: ColorTheme, palette: SemanticPalette) {
        appliedThemeIDs.append(theme.id)
    }
}
