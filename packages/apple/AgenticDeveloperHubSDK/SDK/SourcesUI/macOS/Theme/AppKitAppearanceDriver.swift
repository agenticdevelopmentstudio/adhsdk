import AppKit
import AgenticDeveloperHubSDK

/// The AppKit half of `ThemeManager`: drives `NSApplication.shared.appearance`
/// from the theme's light/dark/auto and repaints themable window backgrounds.
/// Behaviour is verbatim what `ThemeManager` used to do inline before the
/// manager's core moved to `SourcesUI/Shared` to compile for iOS too.
@MainActor
public final class AppKitAppearanceDriver: ThemeAppearanceDriver {

    /// What an `.auto` theme resolves to.
    ///
    /// A theme pinned to `.light` or `.dark` wins outright: its colours *are*
    /// that brightness, and forcing the opposite system appearance would put
    /// light system chrome against a dark themed surface. Only an `.auto` theme
    /// — one that makes no claim — asks this, which is how a host's own
    /// "Appearance: Light / Dark / System" control still does something while
    /// such a theme is active.
    ///
    /// Returning `nil` (the default) means "whatever the system says", which is
    /// what `.auto` meant before any host had a control to ask.
    ///
    /// `@MainActor` on the closure rather than a bare function type: the driver
    /// is main-actor isolated and calls this from there, and a host's answer is
    /// invariably read off main-actor state (a preference object, a window).
    /// Without it every call site pays for a hop it does not need —
    /// `MainActor.assumeIsolated`, whose result must be `Sendable`, which
    /// `NSAppearance` is not.
    public var autoAppearance: @MainActor () -> NSAppearance?

    public init(autoAppearance: @escaping @MainActor () -> NSAppearance? = { nil }) {
        self.autoAppearance = autoAppearance
    }

    public func apply(_ theme: ColorTheme, palette: SemanticPalette) {
        NSApplication.shared.appearance = resolvedAppearance(for: theme)
        let background = NSColor(palette.windowBackground)
        for window in NSApplication.shared.windows where ThemeManager.shouldThemeBackground(of: window) {
            window.backgroundColor = background
        }
    }

    /// The `NSAppearance` to run AppKit's unthemed chrome under.
    private func resolvedAppearance(for theme: ColorTheme) -> NSAppearance? {
        switch theme.appearance {
        case .light, .dark: return theme.appearance.nsAppearance
        case .auto:         return autoAppearance()
        }
    }
}

extension ThemeManager {

    /// The macOS default: drive app-wide appearance through AppKit. Keeps every
    /// `ThemeManager(storage:)` call site behaving exactly as it did when the
    /// AppKit work lived inside the manager.
    public convenience init(storage: any ThemeStorage) {
        self.init(storage: storage, appearanceDriver: AppKitAppearanceDriver())
    }

    /// When true (the default on macOS), the manager drives
    /// `NSApplication.shared.appearance` and repaints themable window
    /// backgrounds as the active theme changes.
    ///
    /// Strictly "is *the AppKit* driver installed?", never "is *a* driver
    /// installed?" — this property owns `AppKitAppearanceDriver` and nothing
    /// else. A host that injected its own `ThemeAppearanceDriver` reads `false`
    /// here and keeps its driver through a write in either direction: the
    /// convenience of a boolean toggle is not worth silently discarding a
    /// driver it knows nothing about. Such a host manages `appearanceDriver`
    /// directly.
    ///
    /// Setting `true` when the AppKit driver is already installed is a no-op
    /// rather than a fresh allocation. Like before, flipping it does not itself
    /// repaint; the next theme change does.
    ///
    /// A `false` → `true` cycle reinstalls the exact `AppKitAppearanceDriver`
    /// instance `false` removed, not a fresh `AppKitAppearanceDriver()` — the
    /// latter's `autoAppearance` defaults to `{ nil }`, which would silently
    /// discard whatever closure the host injected at construction (see
    /// `ThemeManager+UserSettings.swift`). That makes the toggle lossless: a
    /// host can turn AppKit driving off and back on without losing the
    /// closure that answers "what does `.auto` resolve to".
    public var drivesApplicationAppearance: Bool {
        get { appearanceDriver is AppKitAppearanceDriver }
        set {
            if newValue {
                // Only the empty slot is ours to fill: a non-nil driver is
                // either already the AppKit one (no-op) or the host's (theirs).
                if appearanceDriver == nil {
                    appearanceDriver = suspendedAppearanceDriver ?? AppKitAppearanceDriver()
                    suspendedAppearanceDriver = nil
                }
            } else if let driver = appearanceDriver as? AppKitAppearanceDriver {
                suspendedAppearanceDriver = driver
                appearanceDriver = nil
            }
        }
    }

    /// Filters out panels (color/font pickers, etc.) that should keep the
    /// system's own chrome rather than the app's theme.
    static func shouldThemeBackground(of window: NSWindow) -> Bool {
        guard window.styleMask.contains(.titled) else { return false }
        if window is NSColorPanel || window is NSFontPanel { return false }
        return true
    }
}

extension ThemeAppearance {
    var nsAppearance: NSAppearance? {
        switch self {
        case .auto: return nil
        case .dark: return NSAppearance(named: .darkAqua)
        case .light: return NSAppearance(named: .aqua)
        }
    }
}
