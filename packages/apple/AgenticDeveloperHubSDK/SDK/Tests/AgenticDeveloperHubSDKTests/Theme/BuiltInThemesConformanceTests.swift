import Testing
import Foundation
@testable import AgenticDeveloperHubSDK

@Suite("BuiltInThemes conformance")
struct BuiltInThemesConformanceTests {

    @Test("built-in-themes-001: all is handAuthored followed by webPortedNative")
    func testV001_allComposition() {
        let all = BuiltInThemes.all
        #expect(all.count == BuiltInThemes.handAuthored.count + BuiltInThemes.webPortedNative.count)
        #expect(BuiltInThemes.handAuthored.count == 15)
        #expect(Array(all.prefix(15)) == BuiltInThemes.handAuthored)
        #expect(Array(all.dropFirst(15)) == BuiltInThemes.webPortedNative)
    }

    @Test("built-in-themes-002: ids are unique (also BuiltInThemesTests.uniqueIDs)")
    func testV002_uniqueIDs() {
        #expect(Set(BuiltInThemes.all.map(\.id)).count == BuiltInThemes.all.count)
    }

    @Test("built-in-themes-006: lookup miss returns nil")
    func testV006_lookupMiss() {
        #expect(BuiltInThemes.theme(withID: "no-such-id") == nil)
    }

    @Test("built-in-themes-007: lookup is case-sensitive")
    func testV007_lookupExactMatch() {
        #expect(BuiltInThemes.theme(withID: "a1b2c3d4-0001-4000-8000-000000000001") == nil)
    }

    @Test("built-in-themes-008: lookup hit returns Dracula")
    func testV008_lookupHit() {
        let theme = BuiltInThemes.theme(withID: "A1B2C3D4-0003-4000-8000-000000000003")
        #expect(theme?.name == "Dracula")
    }

    @Test("built-in-themes-012: hand-authored order and appearance")
    func testV012_handAuthoredOrderAndAppearance() {
        let handAuthored = BuiltInThemes.handAuthored
        #expect(handAuthored.first?.name == "Solarized Dark")
        #expect(handAuthored.last?.name == "Gruvbox Light")
        #expect(handAuthored.filter { $0.appearance == .dark }.count == 11)
        #expect(handAuthored.filter { $0.appearance == .light }.count == 4)
    }

    @Test("built-in-themes-013: Nord colors are opaque")
    func testV013_opaqueColors() {
        let nord = BuiltInThemes.nord
        #expect(nord.foreground.alpha == 1)
        #expect(!nord.roleOverrides.isEmpty)
        for (role, color) in nord.roleOverrides {
            #expect(color.alpha == 1, "\(role) is not opaque")
        }
    }

    @Test("built-in-themes-014: Solarized Dark overrides only the five chrome roles")
    func testV014_chromeOverrideOnly() {
        let expected: Set<String> = ["surface", "elevatedSurface", "controlBackground", "border", "outline"]
        #expect(Set(BuiltInThemes.solarizedDark.roleOverrides.keys) == expected)
    }

    @Test("built-in-themes-015: Solarized Dark chrome values land in their own roles")
    func testV015_chromeBuilder() {
        let overrides = BuiltInThemes.solarizedDark.roleOverrides
        let expected: [(ThemeRole, String)] = [
            (.surface, "#073642FF"), (.elevatedSurface, "#0A4250FF"), (.controlBackground, "#04313DFF"),
            (.border, "#0E4452FF"), (.outline, "#1D5B69FF")
        ]
        for (role, hex) in expected {
            #expect(overrides[role.rawValue]?.hexString == hex, "\(role)")
        }
        #expect(Set(overrides.values.map(\.hexString)).count == 5)
    }

    @Test("built-in-themes-016: rgb() accepts an optional leading hash",
          .disabled("the rgb helper is private to BuiltInThemes; a test copy would assert only itself"))
    func testV016_hexOptionalHash() {}

    @Test("built-in-themes-017: rgb() traps on invalid hex",
          .disabled("preconditionFailure halts the process; Swift Testing has no death test here"))
    func testV017_hexInvalidTraps() {}

    @Test("built-in-themes-018: Solarized Dark attribution and stable id")
    func testV018_attributionAndStableID() {
        let theme = BuiltInThemes.solarizedDark
        #expect(theme.attribution == "Ethan Schoonover")
        #expect(theme.id == "A1B2C3D4-0001-4000-8000-000000000001")
    }
}
