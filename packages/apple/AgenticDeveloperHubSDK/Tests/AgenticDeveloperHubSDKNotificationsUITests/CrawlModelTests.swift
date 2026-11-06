import AppKit
import XCTest
import AgenticDeveloperHubSDKNotifications
@testable import AgenticDeveloperHubSDKNotificationsUI

/// The crawl's bookkeeping: which notices run on which strip, and which
/// strips open, close or redraw. Pure, so no strip is ever put on screen.
final class CrawlModelTests: XCTestCase {

    private typealias Key = CrawlPresenter.StripKey

    private let topOne = Key(displayID: 1, edge: .top)
    private let topTwo = Key(displayID: 2, edge: .top)
    private let bottomOne = Key(displayID: 1, edge: .bottom)

    func testShowOpensStripsAndJoinsOpenOnes() {
        var model = CrawlModel()
        XCTAssertEqual(model.show("a", on: [topOne, topTwo]), .init(opened: [topOne, topTwo]))
        XCTAssertEqual(model.show("b", on: [topOne]), .init(refreshed: [topOne]))
        XCTAssertEqual(model.ids(on: topOne), ["a", "b"])
        XCTAssertEqual(model.ids(on: topTwo), ["a"])
        XCTAssertEqual(model.order, ["a", "b"])
    }

    func testRemoveClosesStripsLeftEmpty() {
        var model = CrawlModel()
        _ = model.show("a", on: [topOne, topTwo])
        _ = model.show("b", on: [topOne])
        XCTAssertEqual(model.remove("a"), .init(closed: [topTwo], refreshed: [topOne]))
        XCTAssertEqual(model.remove("b"), .init(closed: [topOne]))
        XCTAssertTrue(model.order.isEmpty)
        XCTAssertTrue(model.isEmpty)
        XCTAssertEqual(model.remove("b"), .init(), "removing twice changes nothing")
    }

    func testReplaceOnTheSameStripsRenamesInPlace() {
        var model = CrawlModel()
        _ = model.show("a", on: [topOne])
        _ = model.show("b", on: [topOne])
        XCTAssertEqual(model.replace("a", with: "a2", on: [topOne]), .init(refreshed: [topOne]))
        XCTAssertEqual(model.ids(on: topOne), ["a2", "b"])
        XCTAssertEqual(model.order, ["a2", "b"])
    }

    /// The review's finding: replacing with a notice on the other edge left
    /// the old id behind, so its strip never closed.
    func testReplaceOntoTheOtherEdgeMovesIt() {
        var model = CrawlModel()
        _ = model.show("a", on: [topOne])
        XCTAssertEqual(model.replace("a", with: "a2", on: [bottomOne]), .init(opened: [bottomOne], closed: [topOne]))
        XCTAssertEqual(model.ids(on: bottomOne), ["a2"])
        XCTAssertTrue(model.ids(on: topOne).isEmpty)
        XCTAssertEqual(model.order, ["a2"])
        XCTAssertEqual(model.remove("a2"), .init(closed: [bottomOne]))
        XCTAssertTrue(model.isEmpty)
    }

    func testReplaceFollowsAChangeOfScreens() {
        var model = CrawlModel()
        _ = model.show("a", on: [topOne, topTwo])
        XCTAssertEqual(model.replace("a", with: "a", on: [topOne]), .init(closed: [topTwo], refreshed: [topOne]))
        XCTAssertEqual(model.keys(of: "a"), [topOne])
    }

    func testReplaceDisplacesTheNewIDsOwnPlacement() {
        var model = CrawlModel()
        _ = model.show("a", on: [topOne])
        _ = model.show("b", on: [topTwo])
        XCTAssertEqual(model.replace("a", with: "b", on: [topOne]), .init(closed: [topTwo], refreshed: [topOne]))
        XCTAssertEqual(model.order, ["b"])
        XCTAssertEqual(model.keys(of: "b"), [topOne])
    }

    func testReplaceOfAnUnknownIDShows() {
        var model = CrawlModel()
        XCTAssertEqual(model.replace("x", with: "a", on: [topOne]), .init(opened: [topOne]))
        XCTAssertEqual(model.order, ["a"])
    }

    func testShowOnNoScreenTakesItOff() {
        var model = CrawlModel()
        _ = model.show("a", on: [topOne])
        XCTAssertEqual(model.show("a", on: []), .init(closed: [topOne]))
        XCTAssertTrue(model.order.isEmpty)
    }
}

/// The presenter driven through injected screens and a recording window
/// seam: nothing goes on screen.
@MainActor
final class CrawlPresenterTests: XCTestCase {

    private var screens: [NoticeScreen] = []
    private var rules = NoticeRoutingRules.defaults

    private func profile(_ position: NoticeProfile.Position) -> NoticeProfile {
        var profile = NoticeRoutingRules.defaults.profiles[.fyi]!
        profile.style = .crawl
        profile.position = position
        profile.screens = .all
        profile.autoDismiss = nil
        return profile
    }

    private func makePresenter(_ windowing: RecordingWindowing) -> CrawlPresenter {
        _ = NSApplication.shared
        return CrawlPresenter(
            rules: { [unowned self] in rules }, windowing: windowing, screens: { [unowned self] _ in screens })
    }

    func testReplaceOntoTheOtherEdgeClosesTheOldStripAndStopsWhenEmpty() {
        screens = [testScreen(1)]
        let windowing = RecordingWindowing()
        let presenter = makePresenter(windowing)
        presenter.show(Notice(id: "a", source: "ci", title: "a"), profile: profile(.topRight), actions: .inert)
        XCTAssertEqual(windowing.presented.count, 1)
        XCTAssertTrue(presenter.isAnimating)

        presenter.replace(
            oldID: "a", with: Notice(id: "a2", source: "ci", title: "a2"), profile: profile(.bottomRight),
            actions: .inert)
        XCTAssertEqual(presenter.shownIDs, ["a2"])
        XCTAssertEqual(windowing.presented.count, 2)
        XCTAssertEqual(windowing.dismissed.count, 1, "the top strip closes")

        presenter.remove(id: "a2")
        XCTAssertEqual(windowing.dismissed.count, 2)
        XCTAssertTrue(presenter.shownIDs.isEmpty)
        XCTAssertFalse(presenter.isAnimating, "no strip, no frame timer")
    }

    func testStripCachesDirectionAndRestartsOnNewContent() throws {
        screens = [testScreen(1)]
        rules.crawlLeftToRight = true
        let presenter = makePresenter(RecordingWindowing())
        presenter.show(Notice(id: "a", source: "ci", title: "a"), profile: profile(.bottomLeft), actions: .inert)
        let key = CrawlPresenter.StripKey(displayID: 1, edge: .bottom)
        XCTAssertEqual(presenter.leftToRight(of: key), true)
        presenter.advance(by: 2)
        XCTAssertEqual(try XCTUnwrap(presenter.elapsed(of: key)), 2, accuracy: 0.001)

        rules.crawlLeftToRight = false
        XCTAssertEqual(presenter.leftToRight(of: key), true, "read once per refresh, not per frame")
        presenter.show(Notice(id: "b", source: "ci", title: "b"), profile: profile(.bottomLeft), actions: .inert)
        XCTAssertEqual(presenter.elapsed(of: key), 0, "new content starts its pass over")
        XCTAssertEqual(presenter.leftToRight(of: key), false)
        presenter.remove(id: "a")
        presenter.remove(id: "b")
    }

    func testScreenChangeRepositionsStrips() throws {
        screens = [testScreen(1)]
        let windowing = RecordingWindowing()
        let presenter = makePresenter(windowing)
        presenter.show(Notice(id: "a", source: "ci", title: "a"), profile: profile(.bottomCenter), actions: .inert)
        let panel = try XCTUnwrap(windowing.presented.first)
        XCTAssertEqual(panel.frame.width, 1512)

        screens = [testScreen(1, width: 2560)]
        presenter.screensDidChange()
        XCTAssertEqual(panel.frame.width, 2560)
        XCTAssertEqual(panel.frame.minY, screens[0].visibleFrame.minY)
        presenter.remove(id: "a")
    }
}
