import Testing
import AppKit
import AgenticDeveloperHubSDK
@testable import AgenticDeveloperHubSDKUI

/// The faces the ported themes name have to actually be there.
///
/// A web theme names its face and then fetches it — `old-school-terminal`
/// imports VT323 from Google Fonts, and that face *is* the theme. A native app
/// has no such fetch, and `nsFont(name:size:)` answers `nil` on a machine
/// where nobody installed it, so the bridge falls silently through to the
/// system monospaced face: a green build, a ported theme, and a chat that
/// looks nothing like the website. This suite is what makes that failure loud.
@MainActor
@Suite("ToolkitFonts")
struct ToolkitFontsTests {

    @Test("the bundled VT323 face resolves by name")
    func vt323Resolves() {
        ToolkitFonts.registerBundledFonts()
        #expect(NSFont(name: "VT323", size: 16) != nil)
    }

    @Test("registration is idempotent — a second call still leaves the face resolvable")
    func registrationIsIdempotent() {
        ToolkitFonts.registerBundledFonts()
        ToolkitFonts.registerBundledFonts()
        #expect(NSFont(name: "VT323", size: 16) != nil)
    }

    /// The end of the chain the suite exists for: a terminal theme's body role
    /// resolves to VT323 itself, not to the system fallback. Compared by name
    /// rather than by identity because `nsFont` may hand back a converted
    /// instance for heavier weights.
    @Test("a terminal theme's body font is VT323, not the system fallback")
    func terminalThemeResolvesToItsOwnFace() throws {
        let terminal = try #require(BuiltInThemes.all.first { $0.name == "Old School Terminal" })
        let palette = SemanticPalette(theme: terminal)
        let font = palette.font(.body)
        #expect(font.familyName == "VT323")
        #expect(font != NSFont.monospacedSystemFont(ofSize: font.pointSize, weight: .regular))
    }

    /// A family nobody ships still falls back rather than crashing — the
    /// registration is an addition to the bridge's behaviour, not a
    /// replacement for its fallback.
    @Test("an unknown family still falls back to the system face")
    func unknownFamilyFallsBack() {
        let style = FontStyle(family: "No Such Face 12345", size: 13, weight: .regular, monospaced: true)
        #expect(style.nsFont(scaledSize: 13).familyName != "No Such Face 12345")
    }
}
