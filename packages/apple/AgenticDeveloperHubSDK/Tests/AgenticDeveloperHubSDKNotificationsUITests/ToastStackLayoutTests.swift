import XCTest
import AgenticDeveloperHubSDKNotifications
@testable import AgenticDeveloperHubSDKNotificationsUI

final class ToastStackLayoutTests: XCTestCase {

    private let visible = CGRect(x: 0, y: 0, width: 1000, height: 800)
    private let card = CGSize(width: 300, height: 80)

    func testTopRightStacksDownward() {
        let frames = ToastStackLayout.frames(count: 2, cardSize: card, in: visible, position: .topRight)
        XCTAssertEqual(frames.count, 2)
        XCTAssertEqual(frames[0], CGRect(x: 688, y: 708, width: 300, height: 80))
        XCTAssertEqual(frames[1], CGRect(x: 688, y: 620, width: 300, height: 80))
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
}

@MainActor
final class ScreenSelectorTests: XCTestCase {

    func testEmptyScreenListYieldsNothing() {
        for selection in NoticeProfile.ScreenSelection.allCases {
            XCTAssertTrue(ScreenSelector.screens(for: selection, all: [], main: nil, mouse: .zero).isEmpty)
        }
    }

    func testAllAndMainUseTheGivenScreens() {
        let screens = NSScreen.screens
        guard let main = NSScreen.main ?? screens.first else { return }
        XCTAssertEqual(ScreenSelector.screens(for: .all, all: screens, main: main, mouse: .zero), screens)
        XCTAssertEqual(ScreenSelector.screens(for: .main, all: screens, main: main, mouse: .zero), [main])
        let inside = CGPoint(x: main.frame.midX, y: main.frame.midY)
        XCTAssertEqual(ScreenSelector.screens(for: .cursor, all: screens, main: main, mouse: inside), [main])
        // A pointer off every screen falls back to the main one.
        let nowhere = CGPoint(x: -1_000_000, y: -1_000_000)
        XCTAssertEqual(ScreenSelector.screens(for: .cursor, all: screens, main: main, mouse: nowhere), [main])
    }
}
