import XCTest
@testable import AgenticDeveloperHubSDKNotificationsUI

/// The crawl's scroll position is pure math, so it is tested without a strip.
final class CrawlLayoutTests: XCTestCase {

    private let content: CGFloat = 300
    private let strip: CGFloat = 1000
    private let speed: CGFloat = 100

    private func offset(_ elapsed: TimeInterval, leftToRight: Bool) -> CGFloat {
        CrawlPresenter.offset(
            elapsed: elapsed, speed: speed, contentWidth: content, stripWidth: strip, leftToRight: leftToRight)
    }

    func testRightToLeftStartsOffRightEdge() {
        XCTAssertEqual(offset(0, leftToRight: false), strip)
        XCTAssertEqual(offset(1, leftToRight: false), strip - speed, accuracy: 0.001)
    }

    func testLeftToRightMirrors() {
        XCTAssertEqual(offset(0, leftToRight: true), -content, "starts just off the left edge")
        for elapsed in [0, 0.5, 1, 4.25, 9, 12.9] as [TimeInterval] {
            XCTAssertEqual(
                offset(elapsed, leftToRight: true),
                strip - content - offset(elapsed, leftToRight: false),
                accuracy: 0.001, "at \(elapsed)s")
        }
    }

    func testWrapsAfterContentPasses() {
        // One pass is the strip plus the content: 1300 px at 100 px/s.
        let pass: TimeInterval = 13
        XCTAssertEqual(offset(pass - 0.01, leftToRight: false), -content + 1, accuracy: 0.001,
                       "the content's trailing edge is about to leave the left edge")
        XCTAssertEqual(offset(pass, leftToRight: false), strip, accuracy: 0.001, "and then it starts over")
        XCTAssertEqual(offset(pass + 2, leftToRight: false), offset(2, leftToRight: false), accuracy: 0.001)
        XCTAssertEqual(offset(pass, leftToRight: true), -content, accuracy: 0.001)
    }

    func testDegenerateInputsStayPut() {
        XCTAssertEqual(
            CrawlPresenter.offset(elapsed: 5, speed: 0, contentWidth: content, stripWidth: strip, leftToRight: false),
            strip)
        XCTAssertEqual(
            CrawlPresenter.offset(elapsed: 5, speed: speed, contentWidth: 0, stripWidth: 0, leftToRight: false),
            0)
    }

    func testEdgeFollowsPosition() {
        XCTAssertEqual(CrawlPresenter.Edge(.topLeft), .top)
        XCTAssertEqual(CrawlPresenter.Edge(.topCenter), .top)
        XCTAssertEqual(CrawlPresenter.Edge(.topRight), .top)
        XCTAssertEqual(CrawlPresenter.Edge(.center), .bottom)
        XCTAssertEqual(CrawlPresenter.Edge(.bottomLeft), .bottom)
        XCTAssertEqual(CrawlPresenter.Edge(.bottomRight), .bottom)
    }

    func testStripFrameHugsTheEdge() {
        let visible = CGRect(x: 0, y: 40, width: 1440, height: 835)
        XCTAssertEqual(CrawlPresenter.stripFrame(in: visible, edge: .top, height: 30),
                       CGRect(x: 0, y: 845, width: 1440, height: 30))
        XCTAssertEqual(CrawlPresenter.stripFrame(in: visible, edge: .bottom, height: 30),
                       CGRect(x: 0, y: 40, width: 1440, height: 30))
    }
}
