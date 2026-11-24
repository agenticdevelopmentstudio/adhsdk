import AppKit
import CodeEditSourceEditor

import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreMacOS

/// The source editor's face of the app theme.
///
/// `CodeEditSourceEditor` asks for an `EditorTheme` — a fixed set of syntax
/// attributes — while the rest of the app reads a `SemanticPalette`. Deriving
/// one from the other is what keeps the file viewer inside the theme system
/// rather than carrying a second, hardcoded palette beside it (`dry`): pick a
/// theme and the editor follows it, imported `.itermcolors` schemes included.
///
/// Chrome comes from the semantic roles (`primaryText`, `cursor`, `selection`,
/// `surface`), because those *are* the app-wide meanings. Syntax colors come
/// from the ANSI 16 instead: "keyword" and "string" are not UI roles, and the
/// 16-slot palette is the vocabulary terminal-derived schemes — Solarized,
/// Dracula, Nord, Gruvbox — are actually authored in, so a scheme's own idea of
/// "green" is what strings end up painted with.
///
/// A theme that states its syntax colors outright (see `ColorTheme.syntaxStyles`
/// — a VS Code import, whose `tokenColors` say what *code* looks like) overrides
/// that derivation role by role. Deriving from ANSI is the fallback for schemes
/// that have no such opinion, not the preferred answer for ones that do.
///
/// The bridge lives in `AgenticDeveloperHubSDKMacOS` rather than next to
/// `SemanticPalette+NSColor` in `AgenticDeveloperHubSDKCoreMacOS`, because that is the
/// only target that links `CodeEditSourceEditor`.
extension SemanticPalette {

    /// This palette expressed as a source-editor theme.
    public var editorTheme: EditorTheme {
        EditorTheme(
            // Chrome is untouched by a declared syntax style: `tokenColors` has
            // nothing to say about editor chrome, which comes from the semantic
            // roles the palette half of the import already filled.
            text: .init(color: nsColor(.primaryText)),
            insertionPoint: nsColor(.cursor),
            invisibles: .init(color: nsColor(.placeholderText)),
            background: nsColor(.windowBackground),
            // The caret line sits one elevation above the backdrop, the same
            // relationship a panel has to the window.
            lineHighlight: nsColor(.surface),
            selection: nsColor(.selection),
            keywords: attribute(.keywords),
            commands: attribute(.commands),
            types: attribute(.types),
            attributes: attribute(.attributes),
            // `variables` also carries functions, methods and parameters — see
            // `EditorTheme.mapCapture` — which is why its default is a bright
            // slot (`SyntaxRole.defaultStyle`).
            variables: attribute(.variables),
            values: attribute(.values),
            numbers: attribute(.numbers),
            strings: attribute(.strings),
            characters: attribute(.characters),
            comments: attribute(.comments)
        )
    }

    /// `role` as an editor attribute: the theme's declared style, or the
    /// shared default (`SemanticPalette.syntaxStyle(for:)`, which the TextMate
    /// code theme reads too).
    private func attribute(_ role: SyntaxRole) -> EditorTheme.Attribute {
        let style = syntaxStyle(for: role)
        return .init(color: NSColor(style.color), bold: style.bold, italic: style.italic)
    }
}
