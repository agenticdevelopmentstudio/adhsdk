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

    private func assertInside(
        _ origins: [String: CGPoint],
        _ size: CGSize,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let cell = metrics.cellSize
        for (id, origin) in origins {
            XCTAssertGreaterThanOrEqual(origin.x, 0, id, file: file, line: line)
            XCTAssertGreaterThanOrEqual(origin.y, 0, id, file: file, line: line)
            XCTAssertLessThanOrEqual(origin.x + min(cell.width, size.width), size.width, id, file: file, line: line)
            XCTAssertLessThanOrEqual(origin.y + min(cell.height, size.height), size.height, id, file: file, line: line)
        }
    }

    func test_arranged_overflow_staysInsideContainer() {
        let size = CGSize(width: 300, height: 250)
        let ids = (0..<20).map { "i\($0)" }
        let origins = DesktopIconLayout(metrics: metrics, containerSize: size).arrangedOrigins(for: ids)
        XCTAssertEqual(origins.count, 20)
        assertInside(origins, size)
    }

    func test_free_overflow_staysInsideContainer() {
        let size = CGSize(width: 300, height: 250)
        let ids = (0..<20).map { "i\($0)" }
        let origins = DesktopIconLayout(metrics: metrics, containerSize: size)
            .freeOrigins(for: ids, saved: ["i0": CGPoint(x: 20, y: 20)])
        XCTAssertEqual(origins.count, 20)
        assertInside(origins, size)
    }

    func test_tinyContainer_originsInside() {
        let size = CGSize(width: 50, height: 40)
        let layout = DesktopIconLayout(metrics: metrics, containerSize: size)
        let arranged = layout.arrangedOrigins(for: ["a", "b", "c"])
        let free = layout.freeOrigins(for: ["a", "b", "c"], saved: [:])
        for origin in Array(arranged.values) + Array(free.values) { XCTAssertEqual(origin, .zero) }
    }
}
