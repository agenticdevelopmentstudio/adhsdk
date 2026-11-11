import Foundation

/// `ThemeStorage` backed by `UserDefaults`, for a host that has no settings
/// system of its own.
///
/// `ThemeStorage` exists so a host with a settings system supplies it rather
/// than inheriting ADT's opinion about where preferences live. Plenty of hosts
/// have no such system — a single-window utility, an iOS app whose only
/// preference *is* the theme — and were each about to write this same forty
/// lines. `UserDefaults` is the platform's own answer for exactly that
/// (`native-controls`), so it lives here once.
///
/// The keys are the same two the AgenticDeveloperHubSDK host writes through its own
/// settings system (`theme.custom_themes`, `theme.active_theme_id`) and the
/// encoding is the same JSON, so a host that later grows a settings system and
/// swaps this out for its own conformer finds the user's themes where it left
/// them.
@MainActor
public final class UserDefaultsThemeStorage: ThemeStorage {

    /// The keys, spelled once. They are load-bearing: change either and
    /// already-saved themes are orphaned silently rather than noisily.
    public enum Key {
        public static let customThemes = "theme.custom_themes"
        public static let activeThemeID = "theme.active_theme_id"
    }

    private let defaults: UserDefaults
    /// Written once in `init`, read once in `deinit`, never touched between,
    /// so the nonisolated `deinit` cannot race it. (`isolated deinit` would
    /// say this in the type system, but needs macOS 15.4 / iOS 18.4.)
    nonisolated(unsafe) private var observer: NSObjectProtocol?

    /// The values this object last wrote or last saw. The change hook fires
    /// only when what is stored differs from these, which is what makes it mean
    /// "somebody else moved this".
    ///
    /// A boolean "I am writing" flag cannot do this job:
    /// `UserDefaults.didChangeNotification` is delivered on a later turn of the
    /// run loop, by which time a flag set and cleared around a synchronous
    /// write is already back down — so every write would report itself, and
    /// `ThemeManager` would reload the theme it had just finished applying.
    /// Comparing values also gets the coalesced case right: several writes
    /// followed by one notification, and a foreign write that happens to store
    /// the value we already had, which is genuinely not a change.
    private var lastSeenThemes: Data?
    private var lastSeenActiveID: String?

    public var onExternalChange: (() -> Void)?

    /// - Parameter defaults: where to persist. A host with an app group passes
    ///   its shared suite; the standard defaults are the ordinary answer.
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.lastSeenThemes = defaults.data(forKey: Key.customThemes)
        self.lastSeenActiveID = defaults.string(forKey: Key.activeThemeID)
        // `UserDefaults.didChangeNotification` fires for a change made by
        // *this* process as well as one arriving from another (a shared suite,
        // an iCloud-backed sync); `noticeExternalChange` is what tells them
        // apart.
        observer = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: defaults,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.noticeExternalChange() }
        }
    }

    deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
    }

    public var customThemes: [ColorTheme] {
        get {
            guard let data = defaults.data(forKey: Key.customThemes) else { return [] }
            // A decode failure means the stored blob is from an incompatible
            // shape, not that the user has no themes — but there is nothing
            // useful to do with it either way, and throwing here would take
            // the whole app down over a preference. An empty catalog still
            // yields every built-in theme.
            return (try? JSONDecoder().decode([ColorTheme].self, from: data)) ?? []
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            // Recorded *before* the write, never after: `UserDefaults` delivers
            // its change notification synchronously when the post and the
            // observer's queue are both the main one, so a record written
            // afterwards arrives too late and the object hears its own write.
            lastSeenThemes = data
            defaults.set(data, forKey: Key.customThemes)
        }
    }

    public var activeThemeID: String? {
        get { defaults.string(forKey: Key.activeThemeID) }
        set {
            // Before the write, for the reason `customThemes` states.
            lastSeenActiveID = newValue
            defaults.set(newValue, forKey: Key.activeThemeID)
        }
    }

    private func noticeExternalChange() {
        let themes = defaults.data(forKey: Key.customThemes)
        let active = defaults.string(forKey: Key.activeThemeID)
        guard themes != lastSeenThemes || active != lastSeenActiveID else { return }
        lastSeenThemes = themes
        lastSeenActiveID = active
        onExternalChange?()
    }
}
