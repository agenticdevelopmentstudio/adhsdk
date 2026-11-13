import Foundation
import Testing
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKLanguage

@Suite("CodeTheme")
struct CodeThemeTests {

    // MARK: - Helpers

    private func object(_ json: String) throws -> Any {
        try JSONSerialization.jsonObject(with: Data(json.utf8))
    }

    private func rules(_ theme: CodeTheme) throws -> [[String: Any]] {
        try #require(try object(theme.tokenColorsJSON) as? [[String: Any]])
    }

    /// `#RRGGBB` when opaque: the form the highlighter emits and parses.
    private func rgb(_ color: RGBAColor) -> String {
        String(color.hexString.prefix(7))
    }

    // MARK: - From the palette

    @Test("a palette over an imported theme paints with that theme's own tokenColors")
    func paletteFromImportedThemeUsesItsTokenColors() throws {
        var theme = BuiltInThemes.dracula
        let kept = ##"[{"scope":"keyword.control","settings":{"foreground":"#ABCDEF"}}]"##
        theme.vscodeTokenColors = kept

        let code = CodeTheme(palette: SemanticPalette(theme: theme))

        #expect(code.tokenColorsJSON == kept)
        let palette = SemanticPalette(theme: theme)
        #expect(code.foreground == palette.color(.primaryText))
        #expect(code.background == palette.color(.windowBackground))
    }

    @Test("a built-in theme synthesizes one rule per role from the ANSI defaults")
    func synthesizedThemeUsesAnsiFallbacks() throws {
        let theme = BuiltInThemes.dracula
        let palette = SemanticPalette(theme: theme)
        let synthesized = try rules(CodeTheme(palette: palette))

        #expect(synthesized.count == SyntaxRole.allCases.count)
        let scopes = synthesized.map { $0["scope"] as? String }
        #expect(scopes == SyntaxRole.allCases.map { $0.textMateScopes.joined(separator: ",") })
        #expect(scopes[2] == "entity.name.type,support.type")

        let keywords = try #require(synthesized.first?["settings"] as? [String: String])
        #expect(keywords["foreground"] == rgb(theme.ansi[5]))
        #expect(keywords["fontStyle"] == "bold")

        let commands = try #require(synthesized[1]["settings"] as? [String: String])
        #expect(commands["foreground"] == rgb(theme.ansi[4]))
        #expect(commands["fontStyle"] == "")

        let comments = try #require(synthesized.last?["settings"] as? [String: String])
        #expect(comments["foreground"] == rgb(palette.color(.tertiaryText)))
        #expect(comments["fontStyle"] == "italic")
    }

    @Test("a declared syntax style wins over the default, emphasis included")
    func synthesizedThemeUsesDeclaredStyles() throws {
        let theme = BuiltInThemes.dracula.withSyntaxStyles([
            .keywords: SyntaxStyle(color: RGBAColor(hexString: "11223344")!, italic: true)
        ])
        let keywords = try #require(
            try rules(CodeTheme(palette: SemanticPalette(theme: theme))).first?["settings"] as? [String: String])
        #expect(keywords["foreground"] == "#11223344")
        #expect(keywords["fontStyle"] == "italic")
    }

    // MARK: - From a VS Code theme file

    @Test("a VS Code theme file gives its editor colours and its tokenColors")
    func vscodeThemeDataReadsEditorColours() throws {
        let data = Data("""
        {
            // JSONC, as VS Code accepts
            "type": "dark",
            "colors": { "editor.foreground": "#d4d4d4", "editor.background": "#1E1E1E80", },
            "tokenColors": [
                { "scope": "keyword", "settings": { "foreground": "#569CD6" } },
                { "scope": ["comment"], "settings": { "foreground": "#6A9955", "fontStyle": "italic" } }
            ]
        }
        """.utf8)

        let code = try CodeTheme(vscodeThemeData: data)

        #expect(code.foreground.hexString == "#D4D4D4FF")
        #expect(code.background.hexString == "#1E1E1E80")
        let tokens = try rules(code)
        #expect(tokens.map { $0["scope"] as? String } == ["keyword", nil])
        #expect(tokens.last?["scope"] as? [String] == ["comment"])

        let json = try #require(try object(code.themeJSON) as? [String: Any])
        let colors = try #require(json["colors"] as? [String: String])
        #expect(colors == ["editor.foreground": "#D4D4D4", "editor.background": "#1E1E1E80"])
        #expect((json["tokenColors"] as? [Any])?.count == 2)
    }

    @Test("a missing editor.foreground falls back to the scope-less rule, then to the type default")
    func vscodeThemeDataFallbacks() throws {
        let scopeless = try CodeTheme(vscodeThemeData: Data("""
        { "type": "light", "colors": {},
          "tokenColors": [ { "settings": { "foreground": "#b392f0" } } ] }
        """.utf8))
        #expect(scopeless.foreground.hexString == "#B392F0FF")
        #expect(scopeless.background.hexString == "#FFFFFFFF")

        let bare = try CodeTheme(vscodeThemeData: Data(#"{ "type": "light" }"#.utf8))
        #expect(bare.foreground.hexString == "#333333FF")
        #expect(bare.background.hexString == "#FFFFFFFF")
        #expect(bare.tokenColorsJSON == "[]")

        let dark = try CodeTheme(vscodeThemeData: Data(##"{ "colors": { "foreground": "#FFF" } }"##.utf8))
        #expect(dark.foreground.hexString == "#FFFFFFFF")
        #expect(dark.background.hexString == "#1E1E1EFF")
    }

    @Test("a file whose root is not an object is rejected")
    func vscodeThemeDataRejectsNonObject() {
        #expect(throws: VSCodeThemeParseError.notAnObject) {
            try CodeTheme(vscodeThemeData: Data("[1, 2]".utf8))
        }
    }
}
