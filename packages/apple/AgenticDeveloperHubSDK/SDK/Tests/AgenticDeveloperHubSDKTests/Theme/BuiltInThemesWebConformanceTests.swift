import Testing
import Foundation
@testable import AgenticDeveloperHubSDK

@Suite("BuiltInThemes web-ported conformance")
struct BuiltInThemesWebConformanceTests {

    // theme-web-001 to theme-web-013 are asserted by PortedThemeTests ("Ported web themes").

    @Test("theme-web-014: stable ids for Charcoal and Agentic Development Studio")
    func testWeb014_themeIDStable() {
        #expect(BuiltInThemes.charcoal.id == "B1B6F0E2-0000-4000-8000-000000000101")
        #expect(BuiltInThemes.agenticDevelopmentStudio.id == "B1B6F0E2-0000-4000-8000-000000000121")
    }

    @Test("theme-web-015: ansi fill derives from background, foreground and the normal slots")
    func testWeb015_ansiDerivedFill() {
        for theme in BuiltInThemes.webPorted {
            #expect(theme.ansi[0] == theme.background, "\(theme.name) ansi[0]")
            #expect(theme.ansi[15] == theme.foreground, "\(theme.name) ansi[15]")
            #expect(theme.ansi[1] == theme.ansi[9], "\(theme.name) ansi[1]")
        }
    }

    @Test("theme-web-016: Whimsical uses the first gradient stop")
    func testWeb016_whimsicalGradientFirstStop() {
        let overrides = BuiltInThemes.whimsical.roleOverrides
        #expect(overrides[ThemeRole.personaBubble.rawValue]?.hexString == "#C8506AFF")
        #expect(overrides[ThemeRole.userBubble.rawValue]?.hexString == "#5A4A98FF")
        #expect(overrides[ThemeRole.sendButton.rawValue]?.hexString == "#C8506AFF")
    }

    @Test("theme-web-017: Synthwave '84 selection comes from the cursor colour")
    func testWeb017_selectionFromCursor() {
        let theme = BuiltInThemes.synthwave84
        #expect(theme.cursor.hexString == "#FF7EDBFF")
        #expect(theme.selection.hexString == "#FF7EDB4D")
    }

    @Test("theme-web-018: Mike Fullerton has a transparent send button and no hover")
    func testWeb018_transparentSendButton() {
        let overrides = BuiltInThemes.mikeFullerton.roleOverrides
        #expect(overrides[ThemeRole.sendButton.rawValue]?.hexString == "#00000000")
        #expect(overrides[ThemeRole.sendButtonText.rawValue]?.hexString == "#C4A35AFF")
        #expect(overrides[ThemeRole.sendButtonHover.rawValue] == nil)
    }

    @Test("theme-web-019: CRT Monitor accent slots")
    func testWeb019_ansiAccentSlots() {
        let ansi = BuiltInThemes.crtMonitor.ansi
        #expect(ansi[0].hexString == "#00000000")
        #expect(ansi[3].hexString == "#00FF41FF")
        #expect(ansi[5].hexString == "#005FFFFF")
        #expect(ansi[13].hexString == "#005FFFFF")
    }

    @Test("theme-web-020: the flat Terminal theme has no send-button overrides")
    func testWeb020_flatTerminalNoSendButton() {
        let overrides = BuiltInThemes.terminal.roleOverrides
        #expect(overrides[ThemeRole.sendButton.rawValue] == nil)
        #expect(overrides[ThemeRole.sendButtonHover.rawValue] == nil)
        #expect(overrides[ThemeRole.sendButtonText.rawValue] == nil)
    }

    @Test("theme-web-021: bubble borders are declared only where web declares them")
    func testWeb021_bubbleBordersDeclared() {
        let key = ThemeRole.personaBubbleBorder.rawValue
        #expect(BuiltInThemes.charcoal.roleOverrides[key]?.hexString == "#C4A35A40")
        #expect(BuiltInThemes.signal.roleOverrides[key] == nil)
    }

    @Test("theme-web-022: Techy title and code styles")
    func testWeb022_techyTypography() {
        let typography = BuiltInThemes.techy.typography
        let title = FontStyle(family: "Inter", size: 22, weight: .semibold, monospaced: false)
        let code = FontStyle(family: "JetBrains Mono", size: 12, weight: .regular, monospaced: true)
        #expect(typography.style(.title) == title)
        #expect(typography.style(.code) == code)
    }

    @Test("theme-web-023: Signal declares a send-button hover colour")
    func testWeb023_sendButtonHoverPresent() {
        let hover = BuiltInThemes.signal.roleOverrides[ThemeRole.sendButtonHover.rawValue]
        #expect(hover?.hexString == "#FFC85AFF")
    }

    @Test("theme-web-024: every ported theme is dark and attributed to the SDK")
    func testWeb024_appearanceAndAttribution() {
        for theme in BuiltInThemes.webPorted {
            #expect(theme.appearance == .dark, "\(theme.name)")
            #expect(theme.attribution == "Agentic Developer Hub SDK", "\(theme.name)")
        }
    }

    @Test("theme-web-025: a five-digit hex literal does not parse")
    func testWeb025_invalidHexIsNil() {
        #expect(RGBAColor(hexString: "#12345") == nil)
    }

    @Test("theme-web-026: every ported theme instantiates with parsed colours")
    func testWeb026_allLiteralsParse() {
        #expect(BuiltInThemes.webPorted.count == 21)
        for theme in BuiltInThemes.webPorted {
            #expect(theme.ansi.count == 16, "\(theme.name)")
            #expect(!theme.roleOverrides.isEmpty, "\(theme.name)")
            #expect(theme.typography.styles.count == TextRole.allCases.count, "\(theme.name)")
        }
    }
}
