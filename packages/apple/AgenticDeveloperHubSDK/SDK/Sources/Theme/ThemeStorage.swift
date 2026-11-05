import Foundation

/// Where custom themes are persisted.
///
/// ADT owns the theme model but not a settings system: a host that already has
/// one supplies it here rather than inheriting ADT's opinion about where
/// preferences live. The surface is deliberately exactly what `ThemeStore`
/// touches — a seam wider than its one implementation would be guesswork.
///
/// Built-in themes are never stored: `ThemeStore` concatenates them with
/// `BuiltInThemes.all` at read time, so an empty storage still yields a full
/// catalog.
///
/// `@MainActor` because the store is, and because the host implementations this
/// exists for (settings systems, `UserDefaults` mirrors, observable objects) are
/// main-actor state. `AnyObject` so a `ThemeStore` holding `let storage` can
/// still write through it.
@MainActor
public protocol ThemeStorage: AnyObject {
    /// The user's imported and custom themes, in insertion order. Reading and
    /// writing must round-trip: what is written here is what a later read — or a
    /// later launch — returns.
    var customThemes: [ColorTheme] { get set }

    /// The `ColorTheme.id` of the currently selected theme, or `nil` if none has
    /// ever been chosen (a fresh install). Reading and writing must round-trip,
    /// same as `customThemes`.
    var activeThemeID: String? { get set }

    /// Invoked when `customThemes` or `activeThemeID` changes from outside this
    /// seam — a settings panel bound straight to the underlying setting, a sync
    /// arriving from another device, anything that isn't `ThemeStore`/`ThemeManager`
    /// writing through this protocol. `ThemeManager` sets this to reload and
    /// repaint; without it, a theme chosen elsewhere persists but nothing
    /// redraws until relaunch.
    ///
    /// A conformer with nothing to observe (an in-memory test double, say) can
    /// leave this a plain stored property that's simply never invoked.
    var onExternalChange: (() -> Void)? { get set }
}
