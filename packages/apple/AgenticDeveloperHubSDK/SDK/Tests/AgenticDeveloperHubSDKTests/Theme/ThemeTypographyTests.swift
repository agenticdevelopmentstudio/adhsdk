import Testing
import Foundation
@testable import AgenticDeveloperHubSDK

@Suite("ThemeTypography")
struct ThemeTypographyTests {

    @Test("system typography provides a style for every text role")
    func systemHasAllRoles() {
        let typo = ThemeTypography.system
        for role in TextRole.allCases {
            let style = typo.style(role)
            #expect(style.size > 0)
        }
        // Code is monospaced; body is not.
        #expect(typo.style(.code).monospaced == true)
        #expect(typo.style(.body).monospaced == false)
        // Title is larger than body.
        #expect(typo.style(.title).size > typo.style(.body).size)
    }

    @Test("sizeScale multiplies the effective size of every role")
    func sizeScaleApplies() {
        var typo = ThemeTypography.system
        let baseBody = typo.style(.body).size
        typo.sizeScale = 1.5
        #expect(typo.size(.body) == baseBody * 1.5)
        // The stored style size is unchanged; only the effective size scales.
        #expect(typo.style(.body).size == baseBody)
    }

    @Test("an explicit per-role style overrides the default")
    func explicitStyleWins() {
        var typo = ThemeTypography.system
        typo.styles[TextRole.body.rawValue] = FontStyle(family: "Menlo", size: 17, weight: .bold, monospaced: true)
        #expect(typo.style(.body).family == "Menlo")
        #expect(typo.style(.body).size == 17)
        #expect(typo.style(.body).weight == .bold)
        // Untouched roles still resolve to their defaults.
        #expect(typo.style(.title).size == ThemeTypography.defaultStyle(.title).size)
    }

    @Test("round-trips through Codable")
    func codableRoundTrip() throws {
        var typo = ThemeTypography(sizeScale: 1.25)
        typo.styles[TextRole.title.rawValue] = FontStyle(family: "Avenir Next", size: 24, weight: .heavy)
        let data = try JSONEncoder().encode(typo)
        let decoded = try JSONDecoder().decode(ThemeTypography.self, from: data)
        #expect(decoded == typo)
        #expect(decoded.size(.title) == 24 * 1.25)
    }

    @Test("ColorTheme defaults to system typography and round-trips with custom typography")
    func colorThemeCarriesTypography() throws {
        let plain = ColorTheme(
            name: "X", appearance: .dark,
            foreground: RGBAColor(hexString: "#ffffffff")!,
            background: RGBAColor(hexString: "#000000ff")!,
            cursor: RGBAColor(hexString: "#ffffffff")!,
            selection: RGBAColor(hexString: "#333333ff")!,
            ansi: Array(repeating: RGBAColor(hexString: "#808080ff")!, count: 16)
        )
        #expect(plain.typography == .system)

        var custom = plain
        custom.typography.sizeScale = 1.4
        let data = try JSONEncoder().encode(custom)
        let decoded = try JSONDecoder().decode(ColorTheme.self, from: data)
        #expect(decoded.typography.sizeScale == 1.4)
    }

    @Test("clampedSizeScale falls back to 1.0 for non-finite values")
    func clampNonFinite() {
        #expect(ThemeTypography.clampedSizeScale(.nan) == 1.0)
        #expect(ThemeTypography.clampedSizeScale(.infinity) == 1.0)
        #expect(ThemeTypography.clampedSizeScale(-.infinity) == 1.0)
        #expect(ThemeTypography.clampedSizeScale(9) == 4)
        #expect(ThemeTypography.clampedSizeScale(0.1) == 0.5)
    }

    // MARK: - Conformance vectors

    @Test("typography-004: default styles for heading, caption and button")
    func v004DefaultStyleTable() {
        let heading = ThemeTypography.defaultStyle(.heading)
        let caption = ThemeTypography.defaultStyle(.caption)
        let button = ThemeTypography.defaultStyle(.button)
        #expect(heading.size == 15 && heading.weight == .semibold)
        #expect(caption.size == 11 && caption.weight == .regular)
        #expect(button.size == 13 && button.weight == .medium)
        for style in [heading, caption, button] {
            #expect(style.family == nil)
            #expect(style.monospaced == false)
        }
    }

    @Test("typography-007: style(_:) does not write the default back into styles")
    func v007StyleLookupDoesNotMutate() {
        let typo = ThemeTypography()
        _ = typo.style(.body)
        #expect(typo.styles.isEmpty)
    }

    @Test("typography-008: an override replaces the whole style, with no merge of role defaults")
    func v008StyleLookupWholeEntry() {
        var typo = ThemeTypography()
        typo.styles[TextRole.body.rawValue] = FontStyle(size: 20)
        let style = typo.style(.body)
        #expect(style.size == 20)
        #expect(style.weight == .regular)
        #expect(style.monospaced == false)
        #expect(style.family == nil)
    }

    @Test("typography-010: the empty initialiser equals system, with scale 1 and no styles")
    func v010InitDefaults() {
        #expect(ThemeTypography() == ThemeTypography.system)
        #expect(ThemeTypography.system.sizeScale == 1.0)
        #expect(ThemeTypography.system.styles.isEmpty)
    }

    @Test("typography-011: FontStyle initialiser defaults")
    func v011FontStyleInitDefaults() {
        let style = FontStyle(size: 14)
        #expect(style.family == nil)
        #expect(style.size == 14)
        #expect(style.weight == .regular)
        #expect(style.monospaced == false)
    }

    @Test("typography-012: the scale range is 0.5 through 4")
    func v012ScaleRange() {
        #expect(ThemeTypography.sizeScaleRange.lowerBound == 0.5)
        #expect(ThemeTypography.sizeScaleRange.upperBound == 4)
    }

    @Test("typography-017: the initialiser does not clamp, and size uses the stored scale")
    func v017InitDoesNotClamp() {
        let typo = ThemeTypography(sizeScale: 0)
        #expect(typo.sizeScale == 0)
        #expect(typo.size(.body) == 0)
    }

    @Test("typography-018: an unknown weight fails decoding rather than defaulting")
    func v018DecodeRejectsUnknownWeight() {
        let json = "{\"sizeScale\": 1, \"styles\": {\"body\": "
            + "{\"size\": 13, \"weight\": \"plush\", \"monospaced\": false}}}"
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(ThemeTypography.self, from: Data(json.utf8))
        }
    }

    @Test("typography-019: a payload without styles fails with keyNotFound")
    func v019DecodeRequiresStyles() {
        do {
            _ = try JSONDecoder().decode(ThemeTypography.self, from: Data("{\"sizeScale\": 1}".utf8))
            Issue.record("decoding should have thrown")
        } catch let DecodingError.keyNotFound(key, _) {
            #expect(key.stringValue == "styles")
        } catch {
            Issue.record("expected keyNotFound, got \(error)")
        }
    }

    @Test("typography-020: TextRole raw values, in declaration order")
    func v020RoleCases() {
        #expect(TextRole.allCases.map(\.rawValue) == ["title", "heading", "body", "caption", "code", "button"])
    }

    @Test("typography-021: FontWeight has nine cases from ultraLight to black")
    func v021WeightCases() {
        #expect(FontWeight.allCases.count == 9)
        #expect(FontWeight.allCases.first == .ultraLight)
        #expect(FontWeight.allCases.last == .black)
    }

    @Test("typography-023: an unknown styles key is kept and never read")
    func v023UnknownStylesKey() {
        let plain = ThemeTypography()
        var typo = ThemeTypography()
        typo.styles["footnote"] = FontStyle(size: 9)
        for role in TextRole.allCases {
            #expect(typo.style(role) == plain.style(role))
        }
        #expect(typo.styles["footnote"] == FontStyle(size: 9))
    }

    @Test("typography-024: style sizes are not validated")
    func v024NoSizeValidation() {
        #expect(FontStyle(size: -3).size == -3)
        #expect(ThemeTypography(styles: ["body": FontStyle(size: 0)]).size(.body) == 0)
    }

    @Test("typography-025: clampedSizeScale at and around the range bounds")
    func v025ClampBounds() {
        #expect(ThemeTypography.clampedSizeScale(0) == 0.5)
        #expect(ThemeTypography.clampedSizeScale(0.5) == 0.5)
        #expect(ThemeTypography.clampedSizeScale(1.0667) == 1.0667)
        #expect(ThemeTypography.clampedSizeScale(4) == 4)
    }
}
