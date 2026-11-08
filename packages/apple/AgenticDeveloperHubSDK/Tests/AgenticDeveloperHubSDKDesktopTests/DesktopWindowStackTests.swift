import XCTest
@testable import AgenticDeveloperHubSDKDesktop

final class DesktopWindowStackTests: XCTestCase {
    private let frame = CGRect(x: 0, y: 0, width: 100, height: 100)

    func test_open_new_appendsFront() {
        var stack = DesktopWindowStack()
        XCTAssertTrue(stack.open("a", frame: frame))
        XCTAssertTrue(stack.open("b", frame: frame))
        XCTAssertEqual(stack.frontID, "b")
        XCTAssertEqual(stack.entries.map(\.id), ["a", "b"])
    }

    func test_open_existing_bringsToFront_noDuplicate() {
        var stack = DesktopWindowStack()
        _ = stack.open("a", frame: frame)
        _ = stack.open("b", frame: frame)
        XCTAssertFalse(stack.open("a", frame: CGRect(x: 5, y: 5, width: 9, height: 9)))
        XCTAssertEqual(stack.entries.map(\.id), ["b", "a"])
        XCTAssertEqual(stack.entries.last?.frame, frame)
    }

    func test_close_removes_andFrontBecomesPrevious() {
        var stack = DesktopWindowStack()
        _ = stack.open("a", frame: frame)
        _ = stack.open("b", frame: frame)
        stack.close("b")
        XCTAssertEqual(stack.frontID, "a")
        stack.close("a")
        XCTAssertNil(stack.frontID)
    }

    func test_setFrame_updates() {
        var stack = DesktopWindowStack()
        _ = stack.open("a", frame: frame)
        let moved = CGRect(x: 10, y: 20, width: 30, height: 40)
        stack.setFrame(moved, for: "a")
        XCTAssertEqual(stack.entries.first?.frame, moved)
    }
}
