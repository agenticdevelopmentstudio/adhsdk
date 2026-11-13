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

    /// The rule a token with `scope` takes, by the highlighter's selector
    /// semantics: a selector applies when it is the scope or a dot-separated
    /// prefix of it, and the longest applicable selector wins.
    private func rule(for scope: String, in rules: [[String: Any]]) -> [String: Any]? {
        var best: (length: Int, rule: [String: Any])?
        for rule in rules {
            let selectors = (rule["scope"] as? String)?.split(separator: ",").map(String.init) ?? []
            for selector in selectors where scope == selector || scope.hasPrefix(selector + ".") {
                if let held = best, held.length > selector.count { continue }
                best = (selector.count, rule)
            }
        }
        return best?.rule
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
        #expect(scopes == SyntaxRole.allCases.map { $0.textMateRuleScopes.joined(separator: ",") })
        #expect(scopes[2] == "entity.name.type,entity.name.class,support.type,support.class")

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

    @Test("synthesized rules reach the scopes real grammars emit, not only the importer's query scopes")
    func synthesizedRulesCoverBroadScopes() throws {
        let synthesized = try rules(CodeTheme(palette: SemanticPalette(theme: BuiltInThemes.dracula)))
        func selectors(of scope: String) -> String? {
            rule(for: scope, in: synthesized)?["scope"] as? String
        }
        func written(_ role: SyntaxRole) -> String {
            role.textMateRuleScopes.joined(separator: ",")
        }
        #expect(selectors(of: "comment.block.documentation.swift") == written(.comments))
        #expect(selectors(of: "punctuation.definition.comment.js") == written(.comments))
        #expect(selectors(of: "string.quoted.single.python") == written(.strings))
        #expect(selectors(of: "storage.type.function.swift") == written(.keywords))
        #expect(selectors(of: "storage.modifier.ts") == written(.keywords))
        #expect(selectors(of: "keyword.operator.assignment") == written(.keywords))
        #expect(selectors(of: "keyword.other.import") == written(.keywords))
        #expect(selectors(of: "constant.numeric.integer") == written(.numbers))
        #expect(selectors(of: "support.class.builtin") == written(.types))
        #expect(selectors(of: "constant.character.escape") == written(.characters))
        #expect(selectors(of: "meta.block") == nil)
    }

    @Test("stored token colours that are not a JSON array are ignored and rules are synthesized")
    func corruptStoredTokenColorsSynthesize() throws {
        for corrupt in ["not json", ##"{"scope":"keyword"}"##, ""] {
            var theme = BuiltInThemes.dracula
            theme.vscodeTokenColors = corrupt
            let code = CodeTheme(palette: SemanticPalette(theme: theme))
            #expect(code.tokenColorsJSON != corrupt)
            #expect(try rules(code).count == SyntaxRole.allCases.count)
        }
    }

    @Test("a palette code theme's theme JSON carries its colours and its synthesized rules")
    func paletteThemeJSON() throws {
        let palette = SemanticPalette(theme: BuiltInThemes.dracula)
        let code = CodeTheme(palette: palette)
        let json = try #require(try object(code.themeJSON) as? [String: Any])
        let colors = try #require(json["colors"] as? [String: String])
        #expect(colors == [
            "editor.foreground": rgb(palette.color(.primaryText)),
            "editor.background": rgb(palette.color(.windowBackground))
        ])
        #expect((json["tokenColors"] as? [Any])?.count == SyntaxRole.allCases.count)
    }

    @Test("equal code themes hash alike; a different rule set does not compare equal")
    func hashableConsistency() {
        let palette = SemanticPalette(theme: BuiltInThemes.dracula)
        let first = CodeTheme(palette: palette)
        let second = CodeTheme(palette: palette)
        #expect(first == second)
        #expect(first.hashValue == second.hashValue)
        #expect(Set([first, second]).count == 1)

        let other = CodeTheme(foreground: first.foreground, background: first.background, tokenColorsJSON: "[]")
        #expect(other != first)
        #expect(Set([first, other]).count == 2)
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

    @Test("default colours come from the first scope-less rule that states each; a null scope is scope-less")
    func vscodeThemeDataScopelessPrefersStatedColour() throws {
        let code = try CodeTheme(vscodeThemeData: Data("""
        { "colors": {},
          "tokenColors": [
            { "settings": { "fontStyle": "italic" } },
            { "scope": null, "settings": { "foreground": "#112233" } },
            { "settings": { "background": "#445566" } },
            { "scope": "keyword", "settings": { "foreground": "#FF0000", "background": "#00FF00" } }
          ] }
        """.utf8))
        #expect(code.foreground.hexString == "#112233FF")
        #expect(code.background.hexString == "#445566FF")
    }

    @Test("a file whose root is not an object is rejected")
    func vscodeThemeDataRejectsNonObject() {
        #expect(throws: VSCodeThemeParseError.notAnObject) {
            try CodeTheme(vscodeThemeData: Data("[1, 2]".utf8))
        }
    }
}
