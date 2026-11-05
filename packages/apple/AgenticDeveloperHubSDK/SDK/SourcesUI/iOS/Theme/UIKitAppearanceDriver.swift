#if canImport(UIKit)
import AgenticDeveloperHubSDK
import UIKit

/// The UIKit half of `ThemeManager`, the mirror of `AppKitAppearanceDriver`:
/// it drives every connected window's `overrideUserInterfaceStyle` from the
/// theme's light/dark/auto and paints their backgrounds from the palette.
///
/// UIKit has no `NSApplication.appearance` to set, so "app-wide" here means
/// every window of every connected window scene — which is what a host would
/// otherwise write by hand in each scene delegate, once per scene, and forget
/// in the one that connects later.
@MainActor
public final class UIKitAppearanceDriver: ThemeAppearanceDriver {

    /// What an `.auto` theme resolves to.
    ///
    /// Same contract as the AppKit driver's: a theme pinned to `.light` or
    /// `.dark` wins outright, because its colours *are* that brightness and
    /// forcing the opposite system style would put light system chrome against
    /// a dark themed surface. Only a theme that makes no claim asks this, which
    /// is how a host's own "Appearance: Light / Dark / System" control still
    /// does something while such a theme is active.
    ///
    /// Returning `.unspecified` (the default) means "whatever the system says".
    ///
    /// `@MainActor` on the closure rather than a bare function type, for the
    /// same reason as the AppKit driver's: this is called from main-actor code
    /// and answered from main-actor state, so the isolation belongs in the type
    /// rather than in an `assumeIsolated` at every call site.
    public var autoAppearance: @MainActor () -> UIUserInterfaceStyle

    public init(autoAppearance: @escaping @MainActor () -> UIUserInterfaceStyle = { .unspecified }) {
        self.autoAppearance = autoAppearance
    }

    public func apply(_ theme: ColorTheme, palette: SemanticPalette) {
        let style = resolvedStyle(for: theme)
        let background = palette.windowBackgroundColor
        for window in Self.windows {
            window.overrideUserInterfaceStyle = style
            window.backgroundColor = background
        }
    }

    /// The style to run UIKit's unthemed chrome under. Internal rather than
    /// private so a test can check the decision itself: a unit test has no
    /// connected window scene to read the answer back off.
    func resolvedStyle(for theme: ColorTheme) -> UIUserInterfaceStyle {
        switch theme.appearance {
        case .light: .light
        case .dark: .dark
        case .auto: autoAppearance()
        }
    }

    /// Every window UIKit currently has. Scenes come and go, so this is read at
    /// apply time rather than held: a scene that connects after a theme change
    /// gets the style from its own window's first layout, and one that has gone
    /// away is simply no longer in the list.
    private static var windows: [UIWindow] {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
    }
}

public extension ThemeManager {

    /// The iOS default: drive window appearance through UIKit. The counterpart
    /// of the AppKit convenience initialiser, so a host on either platform
    /// writes `ThemeManager(storage:)` and gets the platform's chrome driven.
    convenience init(storage: any ThemeStorage) {
        self.init(storage: storage, appearanceDriver: UIKitAppearanceDriver())
    }
}
#endif
