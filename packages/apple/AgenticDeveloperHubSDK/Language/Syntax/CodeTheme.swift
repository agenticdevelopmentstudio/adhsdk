import Foundation

import AgenticDeveloperHubSDKCore

/// The colours the TextMate highlighter paints code with: an editor
/// foreground and background, and a VS Code `tokenColors` array.
///
/// Two sources. A VS Code theme file gives all three outright
/// (`init(vscodeThemeData:)`, how a bundled theme such as Dark+ is read). An
/// app palette gives them through the theme model (`init(palette:)`): an
/// imported VS Code theme kept its whole `tokenColors` array
/// (`ColorTheme.vscodeTokenColors`) and paints with it; any other theme gets
/// one rule per `SyntaxRole`, coloured exactly as the source editor colours
/// that role (`SemanticPalette.syntaxStyle(for:)`), so both views of a file
/// agree.
///
/// The token colours stay JSON text: the highlighter takes JSON, and nothing
/// in Swift reads the rules.
public struct CodeTheme: Sendable, Hashable {

    public let foreground: RGBAColor
    public let background: RGBAColor
    /// A JSON array of VS Code `tokenColors` rules.
    public let tokenColorsJSON: String

    public init(foreground: RGBAColor, background: RGBAColor, tokenColorsJSON: String) {
        self.foreground = foreground
        self.background = background
        self.tokenColorsJSON = tokenColorsJSON
    }

    // MARK: - From a VS Code theme file

    /// Reads a VS Code colour-theme file (JSONC accepted). `include` is not
    /// resolved: raw bytes have no directory to resolve it against.
    ///
    /// Not every theme states `editor.foreground` — several bundled ones state
    /// only `colors.foreground`, or paint default text with a scope-less
    /// `tokenColors` rule — so each colour falls back through what such themes
    /// do say before settling on VS Code's own defaults for the theme's type.
    ///
    /// - Throws: `VSCodeThemeParseError.notAnObject` when the root is not an
    ///   object, or the JSONC parser's error when the bytes are not JSON.
    public init(vscodeThemeData data: Data) throws {
        guard let root = try JSONCPreprocessor.jsonObject(from: data) as? [String: Any] else {
            throw VSCodeThemeParseError.notAnObject
        }
        let colors = root["colors"] as? [String: Any] ?? [:]
        let isLight = (root["type"] as? String) == "light"
        let defaults = Self.scopelessSettings(in: root)

        func parsed(_ value: Any?) -> RGBAColor? {
            (value as? String).flatMap(VSCodeThemeImporter.color(fromHex:))
        }

        let foreground = parsed(colors["editor.foreground"])
            ?? parsed(defaults?["foreground"])
            ?? parsed(colors["foreground"])
            ?? Self.opaque(isLight ? 0x33_33_33 : 0xBB_BB_BB)
        let background = parsed(colors["editor.background"])
            ?? parsed(defaults?["background"])
            ?? Self.opaque(isLight ? 0xFF_FF_FF : 0x1E_1E_1E)
        self.init(
            foreground: foreground,
            background: background,
            tokenColorsJSON: VSCodeThemeImporter.tokenColorsJSON(in: root) ?? "[]"
        )
    }

    /// The `settings` of the first `tokenColors` entry with no `scope`: VS
    /// Code's way of stating the default text colour inside the rules.
    private static func scopelessSettings(in root: [String: Any]) -> [String: Any]? {
        guard let entries = root["tokenColors"] as? [Any] else { return nil }
        for case let entry as [String: Any] in entries where entry["scope"] == nil {
            if let settings = entry["settings"] as? [String: Any] { return settings }
        }
        return nil
    }

    private static func opaque(_ rgb: UInt32) -> RGBAColor {
        RGBAColor(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255,
            alpha: 1
        )
    }

    // MARK: - From the palette

    /// The palette's code colours: its primary text on its window background,
    /// painted by the theme's kept `tokenColors`, or by one synthesized rule
    /// per syntax role when it has none.
    public init(palette: SemanticPalette) {
        self.init(
            foreground: palette.color(.primaryText),
            background: palette.color(.windowBackground),
            tokenColorsJSON: palette.theme.vscodeTokenColors ?? Self.synthesizedTokenColors(for: palette)
        )
    }

    /// One rule per `SyntaxRole`, in declaration order, over the role's
    /// TextMate scopes.
    private static func synthesizedTokenColors(for palette: SemanticPalette) -> String {
        let rules: [[String: Any]] = SyntaxRole.allCases.map { role in
            let style = palette.syntaxStyle(for: role)
            return [
                "scope": role.textMateScopes.joined(separator: ","),
                "settings": [
                    "foreground": hex(style.color),
                    "fontStyle": fontStyle(bold: style.bold, italic: style.italic)
                ]
            ]
        }
        return json(rules)
    }

    private static func fontStyle(bold: Bool, italic: Bool) -> String {
        [bold ? "bold" : nil, italic ? "italic" : nil].compactMap { $0 }.joined(separator: " ")
    }

    // MARK: - For the highlighter

    /// The theme object the highlighter's `setTheme` takes:
    /// `{"colors": {"editor.foreground", "editor.background"}, "tokenColors": [...]}`.
    /// The token colours are spliced in as the text they are, never re-parsed.
    public var themeJSON: String {
        let colors = Self.json([
            "editor.foreground": Self.hex(foreground),
            "editor.background": Self.hex(background)
        ])
        return #"{"colors":"# + colors + #","tokenColors":"# + tokenColorsJSON + "}"
    }

    /// Uppercase `#RRGGBB` when opaque, `#RRGGBBAA` otherwise: the two forms
    /// the highlighter parses and emits.
    static func hex(_ color: RGBAColor) -> String {
        let full = color.hexString
        return full.hasSuffix("FF") ? String(full.dropLast(2)) : full
    }

    /// Serializes values this file built itself — strings, arrays and
    /// dictionaries of them — which `JSONSerialization` cannot fail on.
    private static func json(_ object: Any) -> String {
        guard let data = try? JSONSerialization.data(
            withJSONObject: object,
            options: [.sortedKeys, .withoutEscapingSlashes]
        ) else { return "null" }
        return String(bytes: data, encoding: .utf8) ?? "null"
    }

    // MARK: - Hashable

    /// `RGBAColor` is `Equatable` but not `Hashable`; its hex form is its
    /// identity at the precision anything here can express.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(foreground.hexString)
        hasher.combine(background.hexString)
        hasher.combine(tokenColorsJSON)
    }
}
