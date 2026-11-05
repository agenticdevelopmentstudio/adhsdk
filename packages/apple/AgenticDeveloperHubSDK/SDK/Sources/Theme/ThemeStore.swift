import Foundation

/// Errors surfaced when importing a theme from a file, with user-facing text.
public enum ThemeImportError: LocalizedError {
    /// The decoded palette doesn't carry the required number of ANSI colors.
    case invalidPalette(count: Int)
    /// Foreground and background are identical, so all text would be invisible.
    case foregroundMatchesBackground

    public var errorDescription: String? {
        switch self {
        case .invalidPalette(let count):
            return "This theme has \(count) ANSI colors; a valid theme needs exactly "
                + "\(ColorTheme.ansiColorCount)."
        case .foregroundMatchesBackground:
            return "This theme's foreground and background are the same color, "
                + "so its text would be invisible."
        }
    }
}

/// The catalog of available themes: the built-ins concatenated with the user's
/// imported/custom themes, plus mutators that persist custom themes through an
/// injected `ThemeStorage`. Foundation-only (no AppKit, no settings system) so
/// it ships on every platform and is straightforward to test.
@MainActor
public final class ThemeStore {

    /// Where custom themes live. The store itself caches nothing, so every read
    /// reflects whatever storage currently holds.
    private let storage: any ThemeStorage

    public init(storage: any ThemeStorage) {
        self.storage = storage
    }

    /// User-imported/custom themes (persisted), in insertion order.
    public var customThemes: [ColorTheme] { storage.customThemes }

    /// All selectable themes: built-ins first, then custom.
    public var allThemes: [ColorTheme] { BuiltInThemes.all + customThemes }

    /// Looks up any theme (built-in or custom) by ID.
    public func theme(withID id: String) -> ColorTheme? {
        allThemes.first { $0.id == id }
    }

    /// True when `id` refers to a built-in (read-only) theme.
    public func isBuiltIn(id: String) -> Bool {
        BuiltInThemes.theme(withID: id) != nil
    }

    /// Appends a custom theme and persists it.
    @discardableResult
    public func add(_ theme: ColorTheme) -> ColorTheme {
        storage.customThemes = customThemes + [theme]
        return theme
    }

    /// Replaces a custom theme with the same ID (no-op for built-ins / unknown IDs).
    public func update(_ theme: ColorTheme) {
        var themes = customThemes
        guard let index = themes.firstIndex(where: { $0.id == theme.id }) else { return }
        themes[index] = theme
        storage.customThemes = themes
    }

    /// Deletes the custom theme with `id` (no-op for built-ins). Also clears
    /// `activeThemeID` if `id` was the active theme, so storage never keeps
    /// pointing at a theme that no longer exists: left alone, that id is a
    /// lookup `reload()` can never satisfy again, and it snaps back to
    /// "active" without the user choosing it if a later import ever reuses it.
    public func delete(id: String) {
        storage.customThemes = customThemes.filter { $0.id != id }
        if storage.activeThemeID == id {
            storage.activeThemeID = nil
        }
    }

    /// Creates a fresh, editable custom theme seeded from `template` (the active
    /// theme by default is a good starting point supplied by the caller) and
    /// stores it. This backs the sidebar footer's "add" action.
    @discardableResult
    public func addNewTheme(
        basedOn template: ColorTheme = BuiltInThemes.solarizedDark,
        name: String = "New Theme"
    ) -> ColorTheme {
        var seed = template
        seed.id = UUID().uuidString
        seed.name = uniqueName(name)
        seed.isBuiltIn = false
        seed.isImported = false
        seed.attribution = nil
        return add(seed)
    }

    /// Disambiguates `base` against existing theme names by appending " 2", " 3",
    /// … so repeated "add"/"duplicate" actions don't stack indistinguishable rows.
    private func uniqueName(_ base: String) -> String {
        let existing = Set(allThemes.map(\.name))
        guard existing.contains(base) else { return base }
        var suffix = 2
        while existing.contains("\(base) \(suffix)") { suffix += 1 }
        return "\(base) \(suffix)"
    }

    /// Duplicates any theme (built-in, imported, or custom) into a fresh, fully
    /// editable custom theme — the standard way to customize a locked theme.
    @discardableResult
    public func duplicate(_ theme: ColorTheme, nameSuffix: String = " Copy") -> ColorTheme {
        var copy = theme
        copy.id = UUID().uuidString
        copy.name = uniqueName(theme.name + nameSuffix)
        // A duplicate is the user's own theme: never locked, regardless of source.
        copy.isBuiltIn = false
        copy.isImported = false
        return add(copy)
    }

    /// Parses an `.itermcolors` file and stores it as a new **locked** imported
    /// theme (duplicate to edit).
    @discardableResult
    public func importITermColors(contentsOf url: URL) throws -> ColorTheme {
        var theme = try ITermColorsParser.parse(contentsOf: url)
        theme.isImported = true
        return add(theme)
    }

    /// Imports a theme file, choosing the parser by **content** rather than file
    /// extension, so a mis-named file (a `ColorTheme` JSON saved as `.itermcolors`,
    /// or an iTerm plist named `.json`) still imports. A JSON theme's first
    /// non-whitespace byte is `{`; an `.itermcolors` plist's is `<` (xml) or `b`
    /// (bplist).
    @discardableResult
    public func importTheme(contentsOf url: URL) throws -> ColorTheme {
        let data = try Data(contentsOf: url)
        let openBrace: UInt8 = 0x7B
        let whitespace: Set<UInt8> = [0x20, 0x09, 0x0A, 0x0D]
        if data.first(where: { !whitespace.contains($0) }) == openBrace {
            return try importJSON(data: data)
        }
        return try importITermColors(contentsOf: url)
    }

    /// Decodes a `ColorTheme` JSON file and stores it as a new **locked** imported
    /// theme. See `importJSON(data:)` for the sanitizing/validation rules.
    @discardableResult
    public func importJSON(contentsOf url: URL) throws -> ColorTheme {
        try importJSON(data: try Data(contentsOf: url))
    }

    /// Decodes `ColorTheme` JSON and stores it as a locked, deletable import.
    /// A fresh id is always assigned (so it can't collide with a built-in or an
    /// existing custom theme) and `isBuiltIn` is forced off (an imported theme is
    /// never permanent), so a hand-edited or malicious file can't shadow a
    /// built-in or become un-deletable. The palette is validated the same way the
    /// `.itermcolors` path validates, so a structurally broken file is rejected
    /// with a clear error instead of entering the catalog as an unusable theme.
    /// `typography.sizeScale` is clamped to `ThemeTypography.sizeScaleRange` —
    /// the same bound `SemanticPalette.scaled(by:)` enforces on the reader's own
    /// scale — so a file declaring `"sizeScale": 0` can't lay every label out at
    /// zero point size instead of being rejected outright: unlike an invalid
    /// palette or fg==bg, a bad scale doesn't make the theme unusable, only
    /// mis-sized, so it's repaired rather than refused.
    @discardableResult
    public func importJSON(data: Data) throws -> ColorTheme {
        var theme = try JSONDecoder().decode(ColorTheme.self, from: data)
        // A short ANSI array traps consumers that index all 16 slots (e.g. the
        // terminal-profile editor); fg == bg makes every glyph invisible.
        guard theme.hasValidPalette else {
            throw ThemeImportError.invalidPalette(count: theme.ansi.count)
        }
        guard theme.foreground != theme.background else {
            throw ThemeImportError.foregroundMatchesBackground
        }
        theme.typography.sizeScale = ThemeTypography.clampedSizeScale(theme.typography.sizeScale)
        theme.id = UUID().uuidString
        theme.isBuiltIn = false
        theme.isImported = true
        return add(theme)
    }

    /// Encodes a theme as pretty-printed JSON suitable for `importJSON`.
    public func exportJSON(_ theme: ColorTheme) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(theme)
    }
}
