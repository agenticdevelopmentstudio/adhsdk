import AppKit
import XCTest
@testable import AgenticDeveloperHubSDKDesktop

@MainActor
final class DesktopIconRendererTests: XCTestCase {
    func test_symbolIcon_rendersAtRequestedSize() {
        let app = StubApp(identifier: "a")
        let image = DesktopAppIconRenderer.image(for: app, pointSize: 64)
        XCTAssertEqual(image.size, NSSize(width: 64, height: 64))
        XCTAssertNotNil(image.tiffRepresentation)
    }

    func test_missingResourceIcon_fallsBackToPlaceholder() {
        let app = StubApp(identifier: "a", icon: .resource(name: "definitely-not-an-image"))
        let image = DesktopAppIconRenderer.image(for: app, pointSize: 32)
        XCTAssertEqual(image.size, NSSize(width: 32, height: 32))
        XCTAssertNotNil(image.tiffRepresentation)
    }

    func test_symbolIcon_pixelAtCorner_insideTile_isTheTintColor() throws {
        let app = StubApp(identifier: "a", icon: .symbol(name: "star", tint: "#FF0000"))
        let image = DesktopAppIconRenderer.image(for: app, pointSize: 64)
        let tiff = try XCTUnwrap(image.tiffRepresentation)
        let bitmap = try XCTUnwrap(NSBitmapImageRep(data: tiff))
        // Left edge, vertically centred: inside the rounded tile and clear of the white glyph.
        let color = try XCTUnwrap(bitmap.colorAt(x: 4, y: bitmap.pixelsHigh / 2)?.usingColorSpace(.sRGB))
        // The bitmap is in the display's color space, so allow for the conversion from sRGB.
        XCTAssertGreaterThan(color.redComponent, 0.9)
        XCTAssertLessThan(color.greenComponent, 0.25)
        XCTAssertLessThan(color.blueComponent, 0.25)
        XCTAssertEqual(color.alphaComponent, 1, accuracy: 0.02)
    }
}
