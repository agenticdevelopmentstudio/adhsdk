import XCTest
import AgenticDeveloperHubSDKNotifications
@testable import AgenticDeveloperHubSDKNotificationsUI

final class ToastStackGeometryTests: XCTestCase {

    private let visible = CGRect(x: 0, y: 0, width: 1000, height: 800)
    private let stack = CGSize(width: 300, height: 200)

    func testTitleBarSitsAwayFromAnchor() {
        for position in [NoticeProfile.Position.bottomLeft, .bottomCenter, .bottomRight] {
            XCTAssertEqual(ToastStackGeometry.titleBarEdge(for: position), .top, "\(position)")
        }
        for position in [NoticeProfile.Position.topLeft, .topCenter] {
            XCTAssertEqual(ToastStackGeometry.titleBarEdge(for: position), .bottom, "\(position)")
        }
        XCTAssertEqual(ToastStackGeometry.titleBarEdge(for: .center), .top)
    }

    func testWindowFrameReservesMarginAndBar() {
        let frame = ToastStackGeometry.windowFrame(
            stackSize: stack, position: .bottomRight, visible: visible, offset: .zero)
        XCTAssertEqual(frame.width, 300 + 16)
        XCTAssertEqual(frame.height, 200 + 16 + 22)
        // Cards stay 12 pt from the corner, as ToastStackLayout puts them.
        let area = ToastStackGeometry.cardArea(inWindowSize: frame.size, position: .bottomRight)
        XCTAssertEqual(area.size, stack)
        XCTAssertEqual(frame.minX + area.minX, 1000 - 12 - 300)
        XCTAssertEqual(frame.minY + area.minY, 12)

        let top = ToastStackGeometry.windowFrame(
            stackSize: stack, position: .topLeft, visible: visible, offset: .zero)
        let topArea = ToastStackGeometry.cardArea(inWindowSize: top.size, position: .topLeft)
        XCTAssertEqual(top.minY + topArea.maxY, 800 - 12, "the bar is below the cards, so they do not move")
        XCTAssertEqual(ToastStackGeometry.barArea(inWindowSize: top.size, position: .topLeft).minY, 0)
        XCTAssertEqual(ToastStackGeometry.barArea(inWindowSize: frame.size, position: .bottomRight).maxY, frame.height)
    }

    func testOffsetAppliesAndClamps() {
        let base = ToastStackGeometry.windowFrame(
            stackSize: stack, position: .bottomLeft, visible: visible, offset: .zero)
        let moved = ToastStackGeometry.windowFrame(
            stackSize: stack, position: .bottomLeft, visible: visible, offset: NoticeStackOffset(dx: 100, dy: 50))
        XCTAssertEqual(moved.minX, base.minX + 100)
        XCTAssertEqual(moved.minY, base.minY + 50)

        let far = ToastStackGeometry.windowFrame(
            stackSize: stack, position: .bottomLeft, visible: visible, offset: NoticeStackOffset(dx: 9000, dy: -9000))
        XCTAssertEqual(far.maxX, 1000)
        XCTAssertEqual(far.minY, 0)
        XCTAssertEqual(
            ToastStackGeometry.clamp(CGRect(x: -50, y: 900, width: 100, height: 100), to: visible),
            CGRect(x: 0, y: 700, width: 100, height: 100))
    }

    func testOffsetRoundTrip() {
        let anchored = ToastStackGeometry.windowFrame(
            stackSize: stack, position: .center, visible: visible, offset: .zero)
        let offset = NoticeStackOffset(dx: -40, dy: 25)
        let frame = ToastStackGeometry.windowFrame(
            stackSize: stack, position: .center, visible: visible, offset: offset)
        XCTAssertEqual(ToastStackGeometry.offset(of: frame, from: anchored), offset)
    }
}
