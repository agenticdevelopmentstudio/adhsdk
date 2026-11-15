import Testing
import Foundation
@testable import AgenticDeveloperHubSDK

/// Conformance vectors for `SemanticPalette` that no neighbouring suite asserts:
/// the exact blend table, the clear selection edge, the open-question chains,
/// the all-collapsed chart fallback, the identity series' slot-5 exclusion and
/// the project-window colours.
@Suite("SemanticPalette vectors")
struct SemanticPaletteVectorTests {

    private func hex(_ value: String) -> RGBAColor {
        RGBAColor(hexString: value) ?? RGBAColor.clear
    }

    private func grey(_ level: Double) -> RGBAColor {
        RGBAColor(red: level, green: level, blue: level, alpha: 1)
    }

    private func distinctAnsi() -> [RGBAColor] {
        [
            "#000000ff", "#ff0000ff", "#00ff00ff", "#ffff00ff",
            "#0000ffff", "#ff00ffff", "#00ffffff", "#ffffffff",
            "#444444ff", "#ff5555ff", "#55ff55ff", "#ffff55ff",
            "#5555ffff", "#ff55ffff", "#55ffffff", "#ffffffff"
        ].map { hex($0) }
    }

    private func theme(
        ansi: [RGBAColor]? = nil,
        overrides: [ThemeRole: RGBAColor] = [:],
        project: ThemeProjectOptions? = nil
    ) -> ColorTheme {
        var keyed: [String: RGBAColor] = [:]
        for (role, color) in overrides { keyed[role.rawValue] = color }
        return ColorTheme(
            name: "Vectors", appearance: .dark,
            foreground: RGBAColor.opaqueWhite,
            background: RGBAColor.opaqueBlack,
            cursor: RGBAColor.opaqueWhite,
            selection: hex("#445566ff"),
            ansi: ansi ?? distinctAnsi(),
            roleOverrides: keyed,
            project: project
        )
    }

    private func expectGrey(_ color: RGBAColor, _ level: Double) {
        #expect(abs(color.red - level) < 0.0001)
        #expect(abs(color.green - level) < 0.0001)
        #expect(abs(color.blue - level) < 0.0001)
        #expect(color.alpha == 1)
    }

    @Test("semantic-palette-005: backgrounds and lines blend black toward white")
    func v005BackgroundsAndLines() {
        let palette = SemanticPalette(theme: theme())
        expectGrey(palette.windowBackground, 0)
        expectGrey(palette.surface, 0.06)
        expectGrey(palette.elevatedSurface, 0.12)
        expectGrey(palette.controlBackground, 0.09)
        expectGrey(palette.divider, 0.10)
        expectGrey(palette.border, 0.18)
        expectGrey(palette.outline, 0.30)
    }

    @Test("semantic-palette-006: selection edge derives to clear")
    func v006SelectionEdgeClear() {
        let palette = SemanticPalette(theme: theme())
        #expect(palette.color(.selectionEdge) == RGBAColor.clear)
        #expect(palette.color(.selectionEdge).alpha == 0)
    }

    @Test("semantic-palette-007: chat roles chain from the derived accent, not the override")
    func v007ChainsUseDerivedParents() {
        let red = hex("#ff0000ff")
        let source = theme(overrides: [.accent: red])
        let palette = SemanticPalette(theme: source)
        let derivedAccent = source.ansi[4]
        #expect(palette.accent == red)
        #expect(palette.personaName == derivedAccent)
        #expect(palette.sendButton == derivedAccent)
        #expect(palette.chatInputFocus == derivedAccent)
        #expect(palette.personaName != red)
    }

    @Test("semantic-palette-008: card follows the derived elevated surface, not its override")
    func v008CardUsesDerivedElevatedSurface() {
        let override = hex("#aa5500ff")
        let palette = SemanticPalette(theme: theme(overrides: [.elevatedSurface: override]))
        #expect(palette.elevatedSurface == override)
        #expect(palette.card == palette.derived(.elevatedSurface))
        #expect(palette.card != override)
    }

    @Test("semantic-palette-011: chart series fall back to the semantic colors when all collapse")
    func v011ChartFallback() {
        let surface = RGBAColor.opaqueBlack.blended(withFraction: 0.06, of: .opaqueWhite)
        let source = theme(ansi: Array(repeating: surface, count: 16))
        let palette = SemanticPalette(theme: source)
        let semantic = [palette.accent, palette.success, palette.info, palette.warning, palette.danger]
        #expect(palette.chartSeriesColors.count == 5)
        #expect(palette.chartSeriesColors == semantic)
    }

    @Test("semantic-palette-012: identity series omits slot 5 when it equals the accent")
    func v012IdentityOmitsSlotFive() {
        var ansi = distinctAnsi()
        ansi[5] = ansi[4]
        let source = theme(ansi: ansi)
        let palette = SemanticPalette(theme: source)
        #expect(palette.identitySeriesColors == [ansi[6], ansi[13], ansi[14]])
        #expect(!palette.identitySeriesColors.contains(palette.accent))
    }

    @Test("semantic-palette-017: project pane colors come from the theme's project options")
    func v017ProjectOverrides() {
        let backdrop = hex("#112233ff")
        let outline = hex("#336699ff")
        let options = ThemeProjectOptions(paneOutline: outline, paneBackdrop: backdrop)
        let palette = SemanticPalette(theme: theme(project: options))
        #expect(palette.projectPaneBackdrop == backdrop)
        #expect(palette.projectPaneOutline == outline)
        let plain = SemanticPalette(theme: theme())
        #expect(plain.projectPaneBackdrop == plain.elevatedSurface)
        #expect(plain.projectPaneOutline == plain.border)
    }

    @Test("semantic-palette-018: the active pane outline is the accent")
    func v018ActivePaneOutline() {
        let palette = SemanticPalette(theme: theme())
        #expect(palette.projectActivePaneOutline == palette.accent)
        let overridden = SemanticPalette(theme: theme(overrides: [.accent: hex("#ff0000ff")]))
        #expect(overridden.projectActivePaneOutline == overridden.accent)
    }
}
