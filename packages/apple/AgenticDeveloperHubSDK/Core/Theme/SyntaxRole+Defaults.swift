import Foundation

extension SyntaxRole {

    /// The TextMate scopes for this role, in the order to try.
    ///
    /// Read in both directions: `VSCodeThemeImporter` asks a theme's
    /// `tokenColors` which colour paints each scope, and `CodeTheme` writes one
    /// rule per role over them when a theme has no `tokenColors` of its own.
    ///
    /// Not guesses: measured against 20 published Open VSX themes (the Dracula,
    /// GitHub, Material and Night Owl families). Nine of the ten resolve in
    /// **20/20** themes on the single scope named here. `types` resolves in
    /// 16/20 on `entity.name.type`, and in the remaining four — the Night Owl
    /// family — only on `support.type`, which is why it alone carries a second
    /// step and why the chain is ordered rather than a set. This is the reason
    /// these particular scopes are here and not the dozen plausible
    /// alternatives (`keyword`, `entity.name`, `string`, `comment`), each of
    /// which either matched fewer themes or matched an ancestor so general that
    /// a longer rule elsewhere in the file usually won instead.
    public var textMateScopes: [String] {
        switch self {
        case .keywords: ["keyword.control"]
        case .commands: ["entity.name.function"]
        case .types: ["entity.name.type", "support.type"]
        case .attributes: ["entity.other.attribute-name"]
        case .variables: ["variable.other"]
        case .values: ["constant.language"]
        case .numbers: ["constant.numeric"]
        case .strings: ["string.quoted.double"]
        case .characters: ["constant.character"]
        case .comments: ["comment.line"]
        }
    }

    /// How a role is painted when the theme states no syntax style for it.
    public struct DefaultStyle: Sendable {
        /// The ANSI slot the colour comes from, or `nil` to use `fallback`
        /// outright.
        public let ansiIndex: Int?
        /// The semantic role standing in when there is no slot, or the theme is
        /// short of ANSI colours.
        public let fallback: ThemeRole
        public let bold: Bool
        public let italic: Bool

        public init(ansiIndex: Int?, fallback: ThemeRole, bold: Bool = false, italic: Bool = false) {
            self.ansiIndex = ansiIndex
            self.fallback = fallback
            self.bold = bold
            self.italic = italic
        }
    }

    /// The default for this role: one table that the source editor's theme and
    /// the TextMate code theme both read, so a terminal-derived scheme paints
    /// code the same way in both.
    ///
    /// Syntax colours come from the ANSI 16 because that is the vocabulary
    /// terminal-derived schemes — Solarized, Dracula, Nord, Gruvbox — are
    /// authored in, so a scheme's own idea of "green" is what strings end up
    /// painted with. `variables` also carries functions, methods and parameters
    /// in the source editor, so it takes a bright slot that reads clearly at the
    /// density those appear in. Comments have no slot: they recede, so they take
    /// the tertiary text colour.
    public var defaultStyle: DefaultStyle {
        switch self {
        case .keywords: DefaultStyle(ansiIndex: 5, fallback: .accent, bold: true)
        case .commands: DefaultStyle(ansiIndex: 4, fallback: .accent)
        case .types: DefaultStyle(ansiIndex: 6, fallback: .info)
        case .attributes: DefaultStyle(ansiIndex: 3, fallback: .warning)
        case .variables: DefaultStyle(ansiIndex: 12, fallback: .primaryText)
        case .values: DefaultStyle(ansiIndex: 11, fallback: .warning)
        case .numbers: DefaultStyle(ansiIndex: 9, fallback: .danger)
        case .strings: DefaultStyle(ansiIndex: 2, fallback: .success)
        case .characters: DefaultStyle(ansiIndex: 2, fallback: .success)
        case .comments: DefaultStyle(ansiIndex: nil, fallback: .tertiaryText, italic: true)
        }
    }
}

extension SemanticPalette {

    /// How `role` is painted under this palette.
    ///
    /// **A declared style is authoritative, including its absences.** The
    /// defaults make `keywords` bold and `comments` italic, which is right for a
    /// terminal-derived scheme — one has no opinion about weight. A VS Code
    /// theme does, and a role it declares without a `fontStyle` means "no
    /// emphasis". "Night Owl" and "Night Owl (No Italics)" differ in exactly
    /// that: `comments` is italic in one and plain in the other.
    ///
    /// Otherwise the colour is the default's ANSI slot, falling back to its
    /// semantic role when the slot is absent or the theme is short of colours —
    /// a hand-authored or partially imported scheme is not guaranteed all 16,
    /// and a missing slot must not blank out a whole syntax class.
    public func syntaxStyle(for role: SyntaxRole) -> SyntaxStyle {
        if let declared = theme.syntaxStyles[role] { return declared }
        let defaults = role.defaultStyle
        let color = defaults.ansiIndex.flatMap(theme.ansiColor(at:)) ?? color(defaults.fallback)
        return SyntaxStyle(color: color, bold: defaults.bold, italic: defaults.italic)
    }
}
