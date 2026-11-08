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
}
