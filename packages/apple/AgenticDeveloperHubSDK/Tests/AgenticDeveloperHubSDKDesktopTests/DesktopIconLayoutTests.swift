import XCTest
@testable import AgenticDeveloperHubSDKDesktop

final class DesktopIconLayoutTests: XCTestCase {
    private let metrics = DesktopIconLayout.Metrics.large

    func test_arranged_fillsColumnThenNextColumn() {
        let layout = DesktopIconLayout(metrics: metrics, containerSize: CGSize(width: 300, height: 250))
        let origins = layout.arrangedOrigins(for: ["a", "b", "c"])
        XCTAssertEqual(origins["a"], CGPoint(x: 8, y: 8))
        XCTAssertEqual(origins["b"], CGPoint(x: 8, y: 104))
        XCTAssertEqual(origins["c"], CGPoint(x: 104, y: 8))
    }

    func test_arranged_reflowsWhenContainerShrinks() {
        let tall = DesktopIconLayout(metrics: metrics, containerSize: CGSize(width: 400, height: 400))
        let short = DesktopIconLayout(metrics: metrics, containerSize: CGSize(width: 400, height: 120))
        XCTAssertEqual(tall.arrangedOrigins(for: ["a", "b", "c"])["c"], CGPoint(x: 8, y: 200))
        XCTAssertEqual(short.arrangedOrigins(for: ["a", "b", "c"])["c"], CGPoint(x: 200, y: 8))
    }

    func test_free_keepsSavedOrigin() {
        let layout = DesktopIconLayout(metrics: metrics, containerSize: CGSize(width: 400, height: 300))
        let result = layout.freeOrigins(for: ["a"], saved: ["a": CGPoint(x: 150, y: 70)])
        XCTAssertEqual(result["a"], CGPoint(x: 150, y: 70))
    }

    func test_free_placesUnsavedInNextFreeCell() {
        let layout = DesktopIconLayout(metrics: metrics, containerSize: CGSize(width: 400, height: 300))
        // The saved origin sits inside cell (0,0), so that cell is taken.
        let result = layout.freeOrigins(for: ["a", "b", "c"], saved: ["a": CGPoint(x: 20, y: 30)])
        XCTAssertEqual(result["a"], CGPoint(x: 20, y: 30))
        XCTAssertEqual(result["b"], CGPoint(x: 8, y: 104))
        XCTAssertEqual(result["c"], CGPoint(x: 8, y: 200))
    }

    func test_free_ignoresSavedForUnknownIDs() {
        let layout = DesktopIconLayout(metrics: metrics, containerSize: CGSize(width: 400, height: 300))
        let result = layout.freeOrigins(for: ["a"], saved: ["ghost": CGPoint(x: 8, y: 8)])
        XCTAssertEqual(Set(result.keys), ["a"])
        XCTAssertEqual(result["a"], CGPoint(x: 8, y: 8))
    }

    func test_free_clampsSavedOriginOutsideContainer() {
        let layout = DesktopIconLayout(metrics: metrics, containerSize: CGSize(width: 400, height: 300))
        let origin = layout.freeOrigins(for: ["a"], saved: ["a": CGPoint(x: 5000, y: 5000)])["a"]
        XCTAssertEqual(origin, CGPoint(x: 304, y: 204))
        XCTAssertEqual(layout.clamp(CGPoint(x: -10, y: -10)), .zero)
    }
}
