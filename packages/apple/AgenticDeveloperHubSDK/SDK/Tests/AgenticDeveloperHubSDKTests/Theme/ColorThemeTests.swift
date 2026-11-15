import Testing
import Foundation
@testable import AgenticDeveloperHubSDK

@Suite("ColorTheme")
struct ColorThemeTests {

    @Test("round-trips through Codable")
    func codableRoundTrip() throws {
        // Colors persist as 8-bit #RRGGBBAA, so use a grid-exact override value.
        var theme = BuiltInThemes.dracula
        theme.roleOverrides = [ThemeRole.accent.rawValue: RGBAColor(hexString: "#11223344")!]

        let data = try JSONEncoder().encode(theme)
        let decoded = try JSONDecoder().decode(ColorTheme.self, from: data)

        #expect(decoded == theme)
    }

    @Test("attribution and isImported round-trip through Codable")
    func metadataRoundTrip() throws {
        var theme = BuiltInThemes.nord
        theme.isImported = true
        theme.attribution = "Arctic Ice Studio"

        let data = try JSONEncoder().encode(theme)
        let decoded = try JSONDecoder().decode(ColorTheme.self, from: data)

        #expect(decoded == theme)
        #expect(decoded.isImported)
        #expect(decoded.attribution == "Arctic Ice Studio")
    }

    @Test("a shared/hand-authored theme JSON that omits isBuiltIn still decodes")
    func decodesWithoutIsBuiltIn() throws {
        let ansi = Array(repeating: "\"#000000ff\"", count: 16).joined(separator: ",")
        // No "isBuiltIn" key — a file a user would hand-write or receive.
        let json = "{\"id\":\"x\",\"name\":\"Shared\",\"appearance\":\"dark\","
            + "\"foreground\":\"#ffffffff\",\"background\":\"#000000ff\",\"cursor\":\"#ffffffff\","
            + "\"selection\":\"#111111ff\",\"ansi\":[\(ansi)]}"
        let decoded = try JSONDecoder().decode(ColorTheme.self, from: Data(json.utf8))
        #expect(decoded.isBuiltIn == false)
        #expect(decoded.isImported == false)
    }

    @Test("themes persisted before isImported/attribution existed still decode")
    func decodesLegacyWithoutNewFields() throws {
        let ansi = Array(repeating: "\"#000000ff\"", count: 16).joined(separator: ",")
        let legacy = "{\"id\":\"x\",\"name\":\"Legacy\",\"appearance\":\"dark\",\"isBuiltIn\":false,"
            + "\"foreground\":\"#ffffffff\",\"background\":\"#000000ff\",\"cursor\":\"#ffffffff\","
            + "\"selection\":\"#000000ff\",\"ansi\":[\(ansi)]}"
        let decoded = try JSONDecoder().decode(ColorTheme.self, from: Data(legacy.utf8))
        #expect(decoded.isImported == false)
        #expect(decoded.attribution == nil)
    }

    @Test("editability: built-in and imported are locked, custom is editable")
    func editability() {
        #expect(BuiltInThemes.dracula.isLocked)
        #expect(!BuiltInThemes.dracula.isEditable)
        #expect(!BuiltInThemes.dracula.isDeletable)

        var imported = BuiltInThemes.dracula
        imported.isBuiltIn = false
        imported.isImported = true
        #expect(imported.isLocked)
        #expect(!imported.isEditable)
        #expect(imported.isDeletable)

        var custom = BuiltInThemes.dracula
        custom.isBuiltIn = false
        custom.isImported = false
        #expect(custom.isEditable)
        #expect(!custom.isLocked)
        #expect(custom.isDeletable)
    }

    @Test("every built-in theme carries an attribution")
    func builtInsHaveAttribution() {
        for theme in BuiltInThemes.all {
            #expect(theme.attribution?.isEmpty == false, "\(theme.name) missing attribution")
        }
    }

    @Test("ansiColor(at:) returns the color in range and nil out of range")
    func ansiIndexing() {
        let theme = BuiltInThemes.nord
        #expect(theme.ansiColor(at: 0) == theme.ansi[0])
        #expect(theme.ansiColor(at: 15) == theme.ansi[15])
        #expect(theme.ansiColor(at: 16) == nil)
        #expect(theme.ansiColor(at: -1) == nil)
    }

    @Test("hasValidPalette requires exactly 16 ANSI colors")
    func paletteValidity() {
        #expect(BuiltInThemes.dracula.hasValidPalette)

        let short = ColorTheme(
            name: "Short", appearance: .dark,
            foreground: .white, background: .black, cursor: .white, selection: .black,
            ansi: [.black, .white, .black]
        )
        #expect(!short.hasValidPalette)
    }

    @Test("RGBAColor clamps out-of-range and non-finite components to [0, 1]")
    func rgbaClampsComponents() {
        let over = RGBAColor(red: 1.5, green: -0.2, blue: 2.0, alpha: 9)
        #expect(over.red == 1)
        #expect(over.green == 0)
        #expect(over.blue == 1)
        #expect(over.alpha == 1)

        let nonFinite = RGBAColor(red: .nan, green: 0.5, blue: .infinity, alpha: -.infinity)
        #expect(nonFinite.red == 0)       // NaN → 0
        #expect(nonFinite.green == 0.5)
        #expect(nonFinite.blue == 1)      // +∞ → 1
        #expect(nonFinite.alpha == 0)     // -∞ → 0
    }

    // MARK: Vectors color-theme-009 to color-theme-019

    private static func themeJSON(
        ansiCount: Int = 16, foreground: String = "#ffffffff", omit: String? = nil, extra: String = ""
    ) -> String {
        let ansi = Array(repeating: "\"#000000ff\"", count: ansiCount).joined(separator: ",")
        var fields: [String: String] = [
            "id": "\"x\"", "name": "\"Shared\"", "appearance": "\"dark\"",
            "foreground": "\"\(foreground)\"", "background": "\"#000000ff\"",
            "cursor": "\"#ffffffff\"", "selection": "\"#111111ff\"", "ansi": "[\(ansi)]"
        ]
        if let omit { fields.removeValue(forKey: omit) }
        let body = fields.map { "\"\($0.key)\":\($0.value)" }.sorted().joined(separator: ",")
        return "{" + body + extra + "}"
    }

    private static func decode(_ json: String) throws -> ColorTheme {
        try JSONDecoder().decode(ColorTheme.self, from: Data(json.utf8))
    }

    @Test("color-theme-009: decoding fails when the ansi key is absent")
    func v009_missingAnsiThrows() {
        #expect(throws: DecodingError.self) {
            try Self.decode(Self.themeJSON(omit: "ansi"))
        }
    }

    @Test("color-theme-010: absent optional keys decode to their defaults")
    func v010_absentOptionalDefaults() throws {
        let decoded = try Self.decode(Self.themeJSON())
        #expect(decoded.roleOverrides.isEmpty)
        #expect(decoded.typography == .system)
        #expect(decoded.terminal == nil)
        #expect(decoded.project == nil)
    }

    @Test("color-theme-011: the initializer defaults")
    func v011_initializerDefaults() {
        func make() -> ColorTheme {
            ColorTheme(
                name: "Plain", appearance: .dark,
                foreground: .white, background: .black, cursor: .white, selection: .black, ansi: []
            )
        }
        let first = make()
        let second = make()
        #expect(UUID(uuidString: first.id) != nil)
        #expect(UUID(uuidString: second.id) != nil)
        #expect(first.id != second.id)
        #expect(!first.isBuiltIn)
        #expect(!first.isImported)
        #expect(first.attribution == nil)
        #expect(first.roleOverrides.isEmpty)
    }

    @Test("color-theme-012: ThemeAppearance cases and identifier")
    func v012_appearanceCases() {
        #expect(ThemeAppearance.allCases == [.dark, .light, .auto])
        #expect(ThemeAppearance.auto.id == "auto")
    }

    @Test("color-theme-013: decoding does not validate the palette length")
    func v013_shortPaletteDecodes() throws {
        let decoded = try Self.decode(Self.themeJSON(ansiCount: 3))
        #expect(!decoded.hasValidPalette)
    }

    @Test("color-theme-014: a malformed color string is a data-corrupted error")
    func v014_malformedColorThrowsDataCorrupted() {
        do {
            _ = try Self.decode(Self.themeJSON(foreground: "not-a-color"))
            Issue.record("Decoding should have thrown")
        } catch let DecodingError.dataCorrupted(context) {
            #expect(!context.debugDescription.isEmpty)
        } catch {
            Issue.record("Expected a data-corrupted error, got \(error)")
        }
    }

    @Test("color-theme-015: built-in wins over imported")
    func v015_builtInAndImported() {
        var theme = BuiltInThemes.dracula
        theme.isBuiltIn = true
        theme.isImported = true
        #expect(!theme.isEditable)
        #expect(theme.isLocked)
        #expect(!theme.isDeletable)
    }

    @Test("color-theme-016: seventeen ANSI colors decode and index")
    func v016_seventeenAnsiColors() throws {
        let decoded = try Self.decode(Self.themeJSON(ansiCount: 17))
        #expect(!decoded.hasValidPalette)
        #expect(decoded.ansiColor(at: 16) == decoded.ansi[16])
    }

    @Test("color-theme-017: an unknown key is ignored")
    func v017_unknownKeyIgnored() throws {
        let plain = try Self.decode(Self.themeJSON())
        let withExtra = try Self.decode(Self.themeJSON(extra: ",\"extra\":1"))
        #expect(withExtra == plain)
    }

    @Test("color-theme-018: an unknown appearance is rejected")
    func v018_unknownAppearanceThrows() {
        let json = Self.themeJSON().replacingOccurrences(of: "\"dark\"", with: "\"sepia\"")
        #expect(throws: DecodingError.self) {
            try Self.decode(json)
        }
    }

    @Test("color-theme-019: encoding omits nil optionals")
    func v019_encodeOmitsNil() throws {
        let theme = try Self.decode(Self.themeJSON())
        #expect(theme.attribution == nil)
        let data = try JSONEncoder().encode(theme)
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(object["attribution"] == nil)
        #expect(object["terminal"] == nil)
        #expect(object["project"] == nil)
    }
}
