import AppKit
import XCTest
import AgenticDeveloperHubSDK
import AgenticDeveloperHubSDKNotifications
@testable import AgenticDeveloperHubSDKNotificationsUI

@MainActor
final class NoticeColorAppKitTests: XCTestCase {

    private func components(_ color: NSColor) throws -> [CGFloat] {
        let rgb = try XCTUnwrap(color.usingColorSpace(.sRGB))
        return [rgb.redComponent, rgb.greenComponent, rgb.blueComponent, rgb.alphaComponent]
    }

    func testNoticeColorResolution() throws {
        let palette = SemanticPalette(theme: BuiltInThemes.solarizedDark)
        let fallback = NSColor(srgbRed: 0.1, green: 0.2, blue: 0.3, alpha: 1)

        func resolve(_ color: NoticeColor, _ role: ThemeRole) throws -> [CGFloat] {
            try components(color.resolved(system: fallback, themeRole: role, palette: palette))
        }

        XCTAssertEqual(try resolve(.system, .windowBackground), try components(fallback), "system is the fallback")
        XCTAssertEqual(
            try resolve(.theme, .elevatedSurface), try components(palette.nsColor(.elevatedSurface)),
            "theme is the palette role")
        XCTAssertNotEqual(
            try resolve(.theme, .windowBackground), try resolve(.theme, .elevatedSurface),
            "the role the caller names is the one that is read")
        XCTAssertEqual(
            try resolve(.custom(red: 1, green: 0.5, blue: 0.25), .windowBackground), [1, 0.5, 0.25, 1],
            "custom is the RGB value, opaque")
    }
}
