import Foundation
import OSLog
import AgenticDeveloperHubSDK

/// Owns the app-wide active theme. Resolves the selected `ColorTheme` and its
/// `SemanticPalette` from an injected `ThemeStorage`, applies the saved
/// selection at init, and reacts to live changes made through
/// `selectTheme(id:)` (from a theme settings panel).
///
/// Themeable controls read `ThemeManager.shared?.currentPalette` and observe
/// `didChangeNotification` to repaint when the theme changes.
///
/// This class also reacts to changes made *outside* `selectTheme(id:)` — a
/// settings panel bound straight to the underlying setting, or a sync arriving
/// from another device — via `storage.onExternalChange`, which it hooks in
/// `init` to call `reload()`. Without that hook, such a change persists but
/// nothing repaints until relaunch.
///
/// Platform-neutral by construction: everything AppKit-shaped lives behind
/// `ThemeAppearanceDriver`, the same seam shape `ThemeStorage` uses for
/// persistence. macOS callers get `AppKitAppearanceDriver` installed for them
/// by `init(storage:)`; see `AppKitAppearanceDriver.swift`.
@MainActor
public final class ThemeManager {

    /// The raw string moved with the type — it read
    /// `AgenticDeveloperHubSDK.ThemeManager.didChange` while this class lived in
    /// AgenticDeveloperHubSDKMacOS — and no compatibility post was left behind, on
    /// purpose. A notification name is only a shared secret across a boundary
    /// where two builds meet, and there is no such boundary here: everything
    /// that observes this asks for `ThemeManager.didChangeNotification` rather
    /// than spelling the string (checked across every consumer), a plugin
    /// bundle links the host's own image of this framework instead of carrying
    /// its own, and the name is never persisted. Renaming it is therefore a
    /// rename and nothing more.
    ///
    /// Should any of that stop being true — a consumer that writes the string
    /// out, or an XPC service with its own copy of this framework — the fix is
    /// to post both names for a release, not to reach for the old string here.
    public static let didChangeNotification = Notification.Name("AgenticDeveloperHubSDKUI.ThemeManager.didChange")

    /// The live instance. **Weak** — something upstream (the app delegate, a
    /// scene delegate) must hold the strong reference, or every themed view
    /// silently falls back to the default palette the next time it asks.
    public private(set) static weak var shared: ThemeManager?

    public let store: ThemeStore

    public private(set) var currentTheme: ColorTheme
    public private(set) var currentPalette: SemanticPalette

    /// Applies the active theme to app-wide chrome. `nil` means the manager
    /// tracks the theme but paints no chrome of its own.
    public var appearanceDriver: (any ThemeAppearanceDriver)?

    /// The driver most recently removed by `drivesApplicationAppearance = false`
    /// (macOS-only; see `AppKitAppearanceDriver.swift`), kept only so a later
    /// `= true` can reinstall that exact instance — and whatever it captured,
    /// like an injected `autoAppearance` closure — instead of a fresh default
    /// one. Not `public`: `drivesApplicationAppearance` is the only reader/writer.
    var suspendedAppearanceDriver: (any ThemeAppearanceDriver)?

    /// The reader's own multiplier over every theme's typography — what a
    /// host's "Text Size" control writes to. `1` leaves each theme's type
    /// exactly as its designer scaled it; see `SemanticPalette.scaled(by:)`
    /// for why the two scales stay separate.
    ///
    /// It lives here, on the manager, rather than on the view a host happens
    /// to be resizing, because `ThemePaletteObserver` is how every themed view
    /// in the app gets its palette — a bubble, a status line and a composer
    /// each ask for their own, and nothing hands a palette down a view tree.
    /// Scaling at the source is therefore the only place one number reaches
    /// all of them; scaling at a view would resize that view's own labels and
    /// leave its children at the theme's size.
    ///
    /// Not persisted: what a scale means is the host's business (per window,
    /// per account, per document), so the host owns the storage and writes the
    /// restored value here at launch.
    public var textScale: Double = 1 {
        didSet {
            guard textScale != oldValue else { return }
            rebuildPalette()
        }
    }

    private let storage: any ThemeStorage

    private static let logger = Logger(subsystem: "com.mikefullerton.AgenticDeveloperHubSDKUI", category: "ThemeManager")

    public init(storage: any ThemeStorage, appearanceDriver: (any ThemeAppearanceDriver)?) {
        self.storage = storage
        let store = ThemeStore(storage: storage)
        let theme = store.theme(withID: storage.activeThemeID ?? "") ?? BuiltInThemes.solarizedDark
        self.store = store
        self.currentTheme = theme
        self.currentPalette = SemanticPalette(theme: theme)
        self.appearanceDriver = appearanceDriver
        ThemeManager.shared = self
        applyApplicationAppearance()

        // React to a different theme being selected, or the active theme's
        // definition being edited in place, from outside `selectTheme(id:)`.
        storage.onExternalChange = { [weak self] in self?.reload() }
    }

    private func applyApplicationAppearance() {
        appearanceDriver?.apply(currentTheme, palette: currentPalette)
    }

    /// Re-drives app-wide chrome from the theme already active.
    ///
    /// For hosts whose driver reads something the manager does not own — an
    /// "Appearance: Light / Dark / System" preference an `.auto` theme defers
    /// to, say. Such a setting can change while the theme does not, and
    /// nothing else would repaint. No notification is posted: the palette has
    /// not moved, so no themed view has anything new to draw.
    public func refreshApplicationAppearance() {
        applyApplicationAppearance()
    }

    /// Selects a theme by id (built-in or custom), persists the selection, and
    /// applies it. A no-op if `id` is already the active theme.
    public func selectTheme(id: String) {
        storage.activeThemeID = id
        reload()
    }

    private func reload() {
        let theme = store.theme(withID: storage.activeThemeID ?? "") ?? BuiltInThemes.solarizedDark
        // `selectTheme` both writes `storage.activeThemeID` (which fires
        // `onExternalChange` → `reload()`, typically on a later runloop tick)
        // and calls `reload()` synchronously itself, so `reload()` can run
        // twice per selection. Bail when nothing actually changed: the second
        // call is then a no-op (no duplicate notification / repaint), while an
        // in-place edit of the active theme's own definition still differs and
        // proceeds.
        guard theme != currentTheme else { return }
        currentTheme = theme
        Self.logger.info("Active theme: \(theme.name, privacy: .public)")
        rebuildPalette()
    }

    /// Re-resolves the palette from the active theme and the reader's
    /// `textScale`, then tells the app to repaint. The one path out of both a
    /// theme change and a scale change, so neither can forget the other.
    private func rebuildPalette() {
        currentPalette = SemanticPalette(theme: currentTheme).scaled(by: textScale)
        applyApplicationAppearance()
        NotificationCenter.default.post(name: Self.didChangeNotification, object: self)
    }
}
