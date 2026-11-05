import AgenticDeveloperHubSDK

/// Applies a theme to whatever the platform considers app-wide chrome.
/// ADT declares it; each platform supplies its own conformer, the same
/// way `ThemeStorage` splits persistence.
///
/// `ThemeManager` calls this at init and on every theme change. A manager
/// built with no driver simply doesn't drive chrome — which is what
/// `drivesApplicationAppearance = false` means on macOS, and what every
/// platform without an app-wide appearance to drive gets by default.
@MainActor
public protocol ThemeAppearanceDriver: AnyObject {
    func apply(_ theme: ColorTheme, palette: SemanticPalette)
}
