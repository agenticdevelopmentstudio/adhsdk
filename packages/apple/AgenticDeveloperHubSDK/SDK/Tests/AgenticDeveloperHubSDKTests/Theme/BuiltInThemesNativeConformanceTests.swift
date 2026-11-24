import Testing
import Foundation
@testable import AgenticDeveloperHubSDK

@Suite("BuiltInThemes native adjustments conformance")
struct BuiltInThemesNativeConformanceTests {

    private let slate = "#232831FF"
    private let ember = "#17130FFF"

    @Test("native-001: webPortedNative ids match webPorted ids in order")
    func testNative001_nativeListMatchesWebPorted() {
        #expect(BuiltInThemes.webPortedNative.map(\.id) == BuiltInThemes.webPorted.map(\.id))
    }

    @Test("native-002: all is the hand-authored set plus the ported set")
    func testNative002_allCount() {
        #expect(BuiltInThemes.all.count == BuiltInThemes.handAuthored.count + BuiltInThemes.webPorted.count)
    }

    @Test("native-003: a non-Fishlamp theme passes through unchanged")
    func testNative003_dispatchDefault() throws {
        let other = try #require(BuiltInThemes.webPorted.first { $0.id != BuiltInThemes.fishlamp.id })
        #expect(BuiltInThemes.nativeAdjusted(other) == other)
    }

    @Test("native-004: Fishlamp selection becomes cool slate")
    func testNative004_fishlampSelection() {
        #expect(BuiltInThemes.nativeAdjusted(BuiltInThemes.fishlamp).selection.hexString == slate)
    }

    @Test("native-005: Fishlamp card role is the ember tone")
    func testNative005_fishlampCard() {
        let adjusted = BuiltInThemes.nativeAdjusted(BuiltInThemes.fishlamp)
        #expect(adjusted.roleOverrides[ThemeRole.card.rawValue]?.hexString == ember)
    }

    @Test("native-006: Fishlamp selection edge is amber")
    func testNative006_fishlampSelectionEdge() {
        let adjusted = BuiltInThemes.nativeAdjusted(BuiltInThemes.fishlamp)
        #expect(adjusted.roleOverrides[ThemeRole.selectionEdge.rawValue]?.hexString == "#E8A33DFF")
    }

    @Test("native-007: Fishlamp project options carry only the pane backdrop")
    func testNative007_fishlampPaneBackdrop() {
        let project = BuiltInThemes.nativeAdjusted(BuiltInThemes.fishlamp).project
        #expect(project?.paneBackdrop?.hexString == ember)
        #expect(project?.highlightActivePane == nil)
        #expect(project?.paneOutline == nil)
        #expect(project == ThemeProjectOptions(paneBackdrop: RGBAColor(hexString: ember)))
    }

    @Test("native-008: Fishlamp's own chat overrides are merged through")
    func testNative008_overridesMerged() {
        let key = ThemeRole.chatSurface.rawValue
        let adjusted = BuiltInThemes.nativeAdjusted(BuiltInThemes.fishlamp)
        #expect(adjusted.roleOverrides[key] != nil)
        #expect(adjusted.roleOverrides[key] == BuiltInThemes.fishlamp.roleOverrides[key])
        #expect(adjusted.roleOverrides[key]?.hexString == "#17130FF0")
    }

    @Test("native-009: Fishlamp's other fields are untouched")
    func testNative009_untouchedFields() {
        let original = BuiltInThemes.fishlamp
        let adjusted = BuiltInThemes.nativeAdjusted(original)
        #expect(adjusted.id == original.id)
        #expect(adjusted.name == original.name)
        #expect(adjusted.appearance == original.appearance)
        #expect(adjusted.foreground == original.foreground)
        #expect(adjusted.background == original.background)
        #expect(adjusted.cursor == original.cursor)
        #expect(adjusted.ansi == original.ansi)
        #expect(adjusted.typography == original.typography)
    }

    @Test("native-010: the input theme is not mutated")
    func testNative010_inputPreserved() {
        _ = BuiltInThemes.nativeAdjusted(BuiltInThemes.fishlamp)
        #expect(BuiltInThemes.fishlamp.selection.hexString == "#E8A33D4D")
    }

    @Test("native-011: dispatch is by id, not name")
    func testNative011_dispatchByIDIgnoresName() {
        var copy = BuiltInThemes.fishlamp
        copy.name = "Other"
        #expect(BuiltInThemes.nativeAdjusted(copy).selection.hexString == slate)
    }

    @Test("native-012: a changed id gets no adjustment")
    func testNative012_changedIDUnchanged() {
        var copy = BuiltInThemes.fishlamp
        copy.id = UUID().uuidString
        let adjusted = BuiltInThemes.nativeAdjusted(copy)
        #expect(adjusted == copy)
        #expect(adjusted.selection.hexString == "#E8A33D4D")
    }

    @Test("native-013: the adjusted project options replace the theme's own")
    func testNative013_projectReplaced() {
        var copy = BuiltInThemes.fishlamp
        copy.project = ThemeProjectOptions(highlightActivePane: true)
        let project = BuiltInThemes.nativeAdjusted(copy).project
        #expect(project?.highlightActivePane == nil)
        #expect(project?.paneBackdrop?.hexString == ember)
    }

    @Test("native-014: the adjustment hex literals parse")
    func testNative014_hexLiterals() {
        for literal in ["#17130fff", "#232831ff", "#e8a33dff"] {
            #expect(RGBAColor(hexString: literal) != nil, "\(literal)")
        }
    }
}
