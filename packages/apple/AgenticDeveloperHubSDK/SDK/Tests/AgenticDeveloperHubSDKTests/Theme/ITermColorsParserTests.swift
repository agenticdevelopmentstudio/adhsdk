import Testing
import Foundation
@testable import AgenticDeveloperHubSDK

@Suite("ITermColorsParser")
struct ITermColorsParserTests {

    // MARK: Fixtures

    private static func componentDict(
        _ red: Double, _ green: Double, _ blue: Double, alpha: Double = 1
    ) -> [String: Any] {
        ["Red Component": red, "Green Component": green, "Blue Component": blue,
         "Alpha Component": alpha, "Color Space": "sRGB"]
    }

    /// Builds `.itermcolors` plist data. ANSI colors default to opaque black.
    private static func makeData(
        foreground: (Double, Double, Double),
        background: (Double, Double, Double),
        includeCursor: Bool = true,
        includeSelection: Bool = true,
        dropForeground: Bool = false,
        ansi: [(Double, Double, Double)] = Array(repeating: (0, 0, 0), count: 16)
    ) throws -> Data {
        var dict: [String: Any] = [:]
        if !dropForeground { dict["Foreground Color"] = componentDict(foreground.0, foreground.1, foreground.2) }
        dict["Background Color"] = componentDict(background.0, background.1, background.2)
        if includeCursor { dict["Cursor Color"] = componentDict(0.9, 0.9, 0.9) }
        if includeSelection { dict["Selection Color"] = componentDict(0.2, 0.2, 0.2) }
        for index in 0..<16 {
            dict["Ansi \(index) Color"] = componentDict(ansi[index].0, ansi[index].1, ansi[index].2)
        }
        return try PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0)
    }

    // MARK: Happy path

    @Test("parses foreground, background and all 16 ANSI colors")
    func parsesPalette() throws {
        var ansi = Array(repeating: (0.0, 0.0, 0.0), count: 16)
        ansi[5] = (1.0, 0.0, 0.5)
        let data = try Self.makeData(foreground: (1, 1, 1), background: (0, 0, 0), ansi: ansi)

        let theme = try ITermColorsParser.parse(data: data, name: "Test")

        #expect(theme.name == "Test")
        #expect(theme.foreground == RGBAColor(red: 1, green: 1, blue: 1, alpha: 1))
        #expect(theme.background == RGBAColor(red: 0, green: 0, blue: 0, alpha: 1))
        #expect(theme.ansi.count == 16)
        #expect(theme.ansi[5] == RGBAColor(red: 1, green: 0, blue: 0.5, alpha: 1))
        #expect(!theme.isBuiltIn)
    }

    @Test("infers dark appearance from a dark background")
    func infersDark() throws {
        let data = try Self.makeData(foreground: (1, 1, 1), background: (0, 0, 0))
        let theme = try ITermColorsParser.parse(data: data, name: "Dark")
        #expect(theme.appearance == .dark)
    }

    @Test("infers light appearance from a light background")
    func infersLight() throws {
        let data = try Self.makeData(foreground: (0, 0, 0), background: (1, 1, 1))
        let theme = try ITermColorsParser.parse(data: data, name: "Light")
        #expect(theme.appearance == .light)
    }

    @Test("explicit appearance overrides inference")
    func explicitAppearance() throws {
        let data = try Self.makeData(foreground: (1, 1, 1), background: (0, 0, 0))
        let theme = try ITermColorsParser.parse(data: data, name: "Forced", appearance: .light)
        #expect(theme.appearance == .light)
    }

    @Test("rejects a degenerate theme whose foreground equals its background")
    func rejectsForegroundEqualsBackground() throws {
        let data = try Self.makeData(foreground: (0, 0, 0), background: (0, 0, 0))
        #expect(throws: ITermColorsParseError.foregroundMatchesBackground) {
            try ITermColorsParser.parse(data: data, name: "Degenerate")
        }
    }

    @Test("falls back when cursor and selection are absent")
    func fallbacks() throws {
        let data = try Self.makeData(
            foreground: (1, 1, 1), background: (0, 0, 0),
            includeCursor: false, includeSelection: false
        )
        let theme = try ITermColorsParser.parse(data: data, name: "Partial")
        #expect(theme.cursor == theme.foreground)
        #expect(theme.selection == theme.background.blended(withFraction: 0.25, of: theme.foreground))
    }

    // MARK: Errors (fail-fast)

    @Test("throws when the plist is not a dictionary")
    func notADictionary() throws {
        let data = try PropertyListSerialization.data(fromPropertyList: [1, 2, 3], format: .xml, options: 0)
        #expect(throws: ITermColorsParseError.notADictionary) {
            try ITermColorsParser.parse(data: data, name: "Bad")
        }
    }

    @Test("throws when a required color is missing")
    func missingColor() throws {
        let data = try Self.makeData(foreground: (1, 1, 1), background: (0, 0, 0), dropForeground: true)
        #expect(throws: ITermColorsParseError.missingColor("Foreground Color")) {
            try ITermColorsParser.parse(data: data, name: "Bad")
        }
    }

    @Test("throws when a color component is missing")
    func missingComponent() throws {
        var dict: [String: Any] = [:]
        dict["Foreground Color"] = ["Green Component": 1.0, "Blue Component": 1.0]  // no Red Component
        dict["Background Color"] = Self.componentDict(0, 0, 0)
        for index in 0..<16 { dict["Ansi \(index) Color"] = Self.componentDict(0, 0, 0) }
        let data = try PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0)

        let expected = ITermColorsParseError.missingComponent(
            colorKey: "Foreground Color", component: "Red Component"
        )
        #expect(throws: expected) {
            try ITermColorsParser.parse(data: data, name: "Bad")
        }
    }

    // MARK: Source vectors (itermcolors-010 to itermcolors-021)

    private static func channels(_ value: Double) -> [String: Any] {
        ["Red Component": value, "Green Component": value, "Blue Component": value]
    }

    /// The base fixture as a dictionary: white foreground, black background, all 16 ANSI colors black,
    /// cursor (0.9) and selection (0.2).
    private static func baseDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "Foreground Color": componentDict(1, 1, 1),
            "Background Color": componentDict(0, 0, 0),
            "Cursor Color": componentDict(0.9, 0.9, 0.9),
            "Selection Color": componentDict(0.2, 0.2, 0.2)
        ]
        for index in 0..<16 { dict["Ansi \(index) Color"] = componentDict(0, 0, 0) }
        return dict
    }

    private static func plist(
        _ dict: [String: Any], format: PropertyListSerialization.PropertyListFormat = .xml
    ) throws -> Data {
        try PropertyListSerialization.data(fromPropertyList: dict, format: format, options: 0)
    }

    @Test("itermcolors-010: a missing Alpha Component defaults to opaque")
    func v010_alphaDefaultsOpaque() throws {
        var dict = Self.baseDictionary()
        dict["Foreground Color"] = Self.channels(1)
        let theme = try ITermColorsParser.parse(data: Self.plist(dict), name: "Alpha")
        #expect(theme.foreground.alpha == 1.0)
    }

    @Test("itermcolors-011: channels are clamped into 0...1")
    func v011_channelClamping() throws {
        var dict = Self.baseDictionary()
        dict["Foreground Color"] = ["Red Component": 1.2, "Green Component": -0.1, "Blue Component": 0.5]
        let theme = try ITermColorsParser.parse(data: Self.plist(dict), name: "Clamp")
        #expect(theme.foreground == RGBAColor(red: 1.0, green: 0.0, blue: 0.5, alpha: 1.0))
    }

    @Test("itermcolors-012: a missing ANSI color is rejected")
    func v012_missingAnsiColor() throws {
        var dict = Self.baseDictionary()
        dict.removeValue(forKey: "Ansi 7 Color")
        let data = try Self.plist(dict)
        #expect(throws: ITermColorsParseError.missingColor("Ansi 7 Color")) {
            try ITermColorsParser.parse(data: data, name: "NoAnsi")
        }
    }

    @Test("itermcolors-013: the degenerate check runs before the ANSI check")
    func v013_degenerateCheckBeforeAnsi() throws {
        let dict: [String: Any] = ["Foreground Color": Self.channels(0), "Background Color": Self.channels(0)]
        let data = try Self.plist(dict)
        #expect(throws: ITermColorsParseError.foregroundMatchesBackground) {
            try ITermColorsParser.parse(data: data, name: "Degenerate")
        }
    }

    @Test("itermcolors-014: the URL overload names the theme after the file")
    func v014_urlOverloadDefaultName() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appendingPathComponent("Dracula.itermcolors")
        try Self.plist(Self.baseDictionary()).write(to: file)

        let theme = try ITermColorsParser.parse(contentsOf: file)
        #expect(theme.name == "Dracula")
    }

    @Test("itermcolors-015: the default id is a fresh UUID each call")
    func v015_defaultIdIsFreshUUID() throws {
        let data = try Self.plist(Self.baseDictionary())
        let first = try ITermColorsParser.parse(data: data, name: "One")
        let second = try ITermColorsParser.parse(data: data, name: "One")
        #expect(first.id != second.id)
        #expect(UUID(uuidString: first.id) != nil)
        #expect(UUID(uuidString: second.id) != nil)
    }

    @Test("itermcolors-016: Foundation plist errors propagate unchanged")
    func v016_foundationErrorsPropagate() {
        let data = Data("not a plist".utf8)
        #expect {
            try ITermColorsParser.parse(data: data, name: "Junk")
        } throws: { error in
            !(error is ITermColorsParseError)
        }
    }

    @Test("itermcolors-017: a malformed cursor color falls back to the foreground")
    func v017_malformedCursorFallsBack() throws {
        var dict = Self.baseDictionary()
        dict["Cursor Color"] = ["Red Component": 0.5, "Green Component": 0.5]
        let theme = try ITermColorsParser.parse(data: Self.plist(dict), name: "Cursor")
        #expect(theme.cursor == theme.foreground)
    }

    @Test("itermcolors-018: binary and XML plists parse to the same theme")
    func v018_binaryEqualsXML() throws {
        let dict = Self.baseDictionary()
        let xml = try ITermColorsParser.parse(data: Self.plist(dict, format: .xml), name: "Same", id: "fixed")
        let binary = try ITermColorsParser.parse(data: Self.plist(dict, format: .binary), name: "Same", id: "fixed")
        #expect(binary == xml)
    }

    @Test("itermcolors-019: a malformed selection color falls back to a blend")
    func v019_malformedSelectionFallsBack() throws {
        var dict = Self.baseDictionary()
        dict["Selection Color"] = ["Red Component": 0.5]
        let theme = try ITermColorsParser.parse(data: Self.plist(dict), name: "Selection")
        #expect(theme.selection == theme.background.blended(withFraction: 0.25, of: theme.foreground))
    }

    @Test("itermcolors-020: a non-numeric alpha defaults, a non-numeric red is rejected")
    func v020_componentTypesStrict() throws {
        var alphaDict = Self.baseDictionary()
        alphaDict["Foreground Color"] = [
            "Red Component": 1.0, "Green Component": 1.0, "Blue Component": 1.0, "Alpha Component": "x"
        ]
        let theme = try ITermColorsParser.parse(data: Self.plist(alphaDict), name: "Alpha")
        #expect(theme.foreground.alpha == 1.0)

        var redDict = Self.baseDictionary()
        redDict["Foreground Color"] = [
            "Red Component": "x", "Green Component": 1.0, "Blue Component": 1.0
        ]
        let redData = try Self.plist(redDict)
        let expected = ITermColorsParseError.missingComponent(
            colorKey: "Foreground Color", component: "Red Component"
        )
        #expect(throws: expected) {
            try ITermColorsParser.parse(data: redData, name: "Red")
        }
    }

    @Test("itermcolors-021: luminance boundary, alpha-blind appearance, alpha-aware equality")
    func v021_luminanceBoundaryAndAlpha() throws {
        // (a) A grey whose relative luminance is at the 0.5 boundary is light.
        var channel = 0.7354
        while RGBAColor(red: channel, green: channel, blue: channel, alpha: 1).isDark { channel += 0.0001 }
        let boundary = RGBAColor(red: channel, green: channel, blue: channel, alpha: 1)
        #expect(abs(boundary.relativeLuminance - 0.5) < 0.001)
        var lightDict = Self.baseDictionary()
        lightDict["Background Color"] = Self.channels(channel)
        let light = try ITermColorsParser.parse(data: Self.plist(lightDict), name: "Boundary")
        #expect(light.appearance == .light)

        // (b) Background alpha does not change the appearance.
        var translucent = Self.baseDictionary()
        translucent["Background Color"] = [
            "Red Component": 0.0, "Green Component": 0.0, "Blue Component": 0.0, "Alpha Component": 0.1
        ]
        let faint = try ITermColorsParser.parse(data: Self.plist(translucent), name: "Faint")
        let opaque = try ITermColorsParser.parse(data: Self.plist(Self.baseDictionary()), name: "Opaque")
        #expect(faint.appearance == .dark)
        #expect(faint.appearance == opaque.appearance)

        // (c) Same colour, different alpha: not a degenerate theme.
        var halfAlpha = Self.baseDictionary()
        halfAlpha["Foreground Color"] = [
            "Red Component": 0.0, "Green Component": 0.0, "Blue Component": 0.0, "Alpha Component": 0.5
        ]
        halfAlpha["Background Color"] = Self.channels(0)
        let distinct = try ITermColorsParser.parse(data: Self.plist(halfAlpha), name: "Distinct")
        #expect(distinct.foreground != distinct.background)
    }
}
