import XCTest
import AgenticDeveloperHubSDKNotifications
@testable import AgenticDeveloperHubSDKNotificationsUI

final class ToastStackLayoutTests: XCTestCase {

    private let visible = CGRect(x: 0, y: 0, width: 1000, height: 800)
    private let card = CGSize(width: 300, height: 80)

    func testTopLeftStacksDownward() {
        let frames = ToastStackLayout.frames(count: 2, cardSize: card, in: visible, position: .topLeft)
        XCTAssertEqual(frames.count, 2)
        XCTAssertEqual(frames[0], CGRect(x: 12, y: 708, width: 300, height: 80))
        XCTAssertEqual(frames[1], CGRect(x: 12, y: 620, width: 300, height: 80))
    }

    func testBottomRightStacksUpward() {
        let frames = ToastStackLayout.frames(count: 2, cardSize: card, in: visible, position: .bottomRight)
        XCTAssertEqual(frames[0], CGRect(x: 688, y: 12, width: 300, height: 80))
        XCTAssertEqual(frames[1], CGRect(x: 688, y: 100, width: 300, height: 80))
    }

    func testBottomCenterStacksUpward() {
        let frames = ToastStackLayout.frames(count: 2, cardSize: card, in: visible, position: .bottomCenter)
        XCTAssertEqual(frames[0], CGRect(x: 350, y: 12, width: 300, height: 80))
        XCTAssertEqual(frames[1], CGRect(x: 350, y: 100, width: 300, height: 80))
    }

    func testCenterStacksDownFromMiddle() {
        let frames = ToastStackLayout.frames(count: 2, cardSize: card, in: visible, position: .center)
        XCTAssertEqual(frames[0], CGRect(x: 350, y: 360, width: 300, height: 80))
        XCTAssertEqual(frames[1], CGRect(x: 350, y: 272, width: 300, height: 80))
    }

    func testCountZeroIsEmpty() {
        XCTAssertTrue(ToastStackLayout.frames(count: 0, cardSize: card, in: visible, position: .topLeft).isEmpty)
        XCTAssertTrue(ToastStackLayout.frames(count: -1, cardSize: card, in: visible, position: .topLeft).isEmpty)
    }

    func testTopLeftHonoursMarginAndOffsetVisibleFrame() {
        let offset = CGRect(x: 1000, y: 25, width: 1000, height: 800)
        let frames = ToastStackLayout.frames(count: 1, cardSize: card, in: offset, position: .topLeft, margin: 20)
        XCTAssertEqual(frames[0], CGRect(x: 1020, y: 725, width: 300, height: 80))
    }

    func testMixedHeightsStackWithoutOverlap() {
        let sizes = [CGSize(width: 300, height: 80), CGSize(width: 300, height: 140)]
        let frames = ToastStackLayout.frames(sizes: sizes, in: visible, position: .bottomRight)
        XCTAssertEqual(frames[0], CGRect(x: 688, y: 12, width: 300, height: 80))
        XCTAssertEqual(frames[1], CGRect(x: 688, y: 100, width: 300, height: 140))
    }

    func testCenterStackThatOutgrowsTheLowerHalfMovesUpToStayOnScreen() {
        // Five 200-pt alerts need 1032 pt with spacing; below the middle there are 400.
        let tall = CGSize(width: 440, height: 150)
        let frames = ToastStackLayout.frames(count: 5, cardSize: tall, in: visible, position: .center)
        for frame in frames {
            XCTAssertGreaterThanOrEqual(frame.minY, visible.minY + 12, "\(frame) runs off the bottom")
            XCTAssertLessThanOrEqual(frame.maxY, visible.maxY - 12, "\(frame) runs off the top")
        }
        for (newer, older) in zip(frames, frames.dropFirst()) {
            XCTAssertLessThanOrEqual(older.maxY, newer.minY, "cards overlap")
        }
    }

    func testStackTallerThanTheScreenIsClampedInsideIt() {
        let tall = CGSize(width: 440, height: 300)
        for position in NoticeProfile.Position.allCases {
            let frames = ToastStackLayout.frames(count: 6, cardSize: tall, in: visible, position: position)
            for frame in frames {
                XCTAssertTrue(visible.insetBy(dx: 12, dy: 12).contains(frame), "\(position): \(frame)")
            }
        }
    }
}

@MainActor
final class ScreenSelectorTests: XCTestCase {

    func testEmptyScreenListYieldsNothing() {
        for selection in NoticeProfile.ScreenSelection.allCases {
            XCTAssertTrue(ScreenSelector.screens(for: selection, all: [], main: nil).isEmpty)
        }
    }

    func testAllAndMainUseTheGivenScreens() {
        let screens = NSScreen.screens
        guard let main = NSScreen.main ?? screens.first else { return }
        XCTAssertEqual(ScreenSelector.screens(for: .all, all: screens, main: main), screens)
        XCTAssertEqual(ScreenSelector.screens(for: .main, all: screens, main: main), [main])
        // No main screen falls back to the first one.
        XCTAssertEqual(ScreenSelector.screens(for: .main, all: screens, main: nil), [screens[0]])
    }
}
