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

    private func profiles(_ position: NoticeProfile.Position) -> [NoticeProfile] {
        [NoticeProfile(style: .crawl, position: position)]
    }

    private func makePresenter(_ windowing: RecordingWindowing) -> CrawlPresenter {
        _ = NSApplication.shared
        return CrawlPresenter(
            rules: { [unowned self] in rules }, windowing: windowing, screens: { [unowned self] _ in screens })
    }

    func testReplaceAfterTheEdgeSettingChangesClosesTheOldStripAndStopsWhenEmpty() {
        screens = [testScreen(1)]
        let windowing = RecordingWindowing()
        let presenter = makePresenter(windowing)
        presenter.show(Notice(id: "a", source: "ci", title: "a"), profiles: profiles(.topLeft), actions: .inert)
        XCTAssertEqual(windowing.presented.count, 1)
        XCTAssertTrue(presenter.isAnimating)

        rules.crawl.edge = rules.crawl.edge == .top ? .bottom : .top
        presenter.replace(
            oldID: "a", with: Notice(id: "a2", source: "ci", title: "a2"), profiles: profiles(.bottomRight),
            actions: .inert)
        XCTAssertEqual(presenter.shownIDs, ["a2"])
        XCTAssertEqual(windowing.presented.count, 2)
        XCTAssertEqual(windowing.dismissed.count, 1, "the top strip closes")

        presenter.remove(id: "a2")
        XCTAssertEqual(windowing.dismissed.count, 2)
        XCTAssertTrue(presenter.shownIDs.isEmpty)
        XCTAssertFalse(presenter.isAnimating, "no strip, no frame timer")
    }

    private func crawlProfiles() -> [NoticeProfile] {
        [NoticeProfile(style: .crawl, position: .bottomCenter)]
    }

    func testCrawlUsesSettingsEdgeSpeedAndTextSize() throws {
        screens = [testScreen(1)]
        rules.crawl = CrawlSettings(edge: .top, speed: 200, textSize: 20)
        let windowing = RecordingWindowing()
        let presenter = makePresenter(windowing)
        presenter.show(Notice(id: "a", source: "ci", title: "a"), profiles: crawlProfiles(), actions: .inert)

        let panel = try XCTUnwrap(windowing.presented.first)
        XCTAssertEqual(panel.frame.height, 34, "textSize + 14")
        XCTAssertEqual(panel.frame.maxY, screens[0].visibleFrame.maxY, "the setting's edge, not the item's position")

        let key = CrawlPresenter.StripKey(displayID: 1, edge: .top)
        let view = try XCTUnwrap(presenter.stripView(of: key))
        XCTAssertEqual(view.textSize, 20)
        XCTAssertEqual(view.labelFontSizes, [20])
        let width = view.bounds.width
        presenter.advance(by: 1)
        XCTAssertEqual(view.contentOriginX, width - 200, accuracy: 0.5, "speed is the setting's")
        presenter.remove(id: "a")
    }

    func testCrawlHidesBackgroundWhenOff() throws {
        screens = [testScreen(1)]
        rules.crawl.showsBackground = false
        let presenter = makePresenter(RecordingWindowing())
        presenter.show(Notice(id: "a", source: "ci", title: "a"), profiles: crawlProfiles(), actions: .inert)
        let key = CrawlPresenter.StripKey(displayID: 1, edge: .bottom)
        XCTAssertTrue(try XCTUnwrap(presenter.stripView(of: key)).background.isHidden)

        rules.crawl.showsBackground = true
        rules.crawl.background = .custom(red: 0, green: 0, blue: 1)
        rules.crawl.backgroundOpacity = 0.5
        presenter.rulesDidChange()
        let view = try XCTUnwrap(presenter.stripView(of: key))
        XCTAssertFalse(view.background.isHidden)
        let cgColor = try XCTUnwrap(view.background.layer?.backgroundColor)
        let rgb = try XCTUnwrap(NSColor(cgColor: cgColor)?.usingColorSpace(.sRGB))
        XCTAssertEqual(rgb.blueComponent, 1, accuracy: 0.01)
        XCTAssertEqual(rgb.alphaComponent, 0.5, accuracy: 0.01)
        presenter.remove(id: "a")
    }

    func testSystemBackgroundFollowsLightAndDark() throws {
        _ = NSApplication.shared
        let view = CrawlStripView(settings: CrawlSettings(background: .system, backgroundOpacity: 1))
        func backgroundColor(_ appearance: NSAppearance.Name) throws -> NSColor {
            view.appearance = NSAppearance(named: appearance)
            view.viewDidChangeEffectiveAppearance()
            let cgColor = try XCTUnwrap(view.background.layer?.backgroundColor)
            return try XCTUnwrap(NSColor(cgColor: cgColor)?.usingColorSpace(.sRGB))
        }
        let dark = try backgroundColor(.darkAqua)
        let light = try backgroundColor(.aqua)
        XCTAssertNotEqual(dark.redComponent, light.redComponent, accuracy: 0.05, "the system color re-resolves")
    }

    func testCrawlStripHeightFollowsTextSize() {
        XCTAssertEqual(CrawlPresenter.stripHeight(textSize: 10), 28, "never under 28")
        XCTAssertEqual(CrawlPresenter.stripHeight(textSize: 13), 28)
        XCTAssertEqual(CrawlPresenter.stripHeight(textSize: 14), 28)
        XCTAssertEqual(CrawlPresenter.stripHeight(textSize: 20), 34)
        XCTAssertEqual(CrawlPresenter.stripHeight(textSize: 28), 42)
    }

    func testItemOpacityFollowsTheSetting() throws {
        screens = [testScreen(1)]
        rules.crawl.itemOpacity = 0.4
        let presenter = makePresenter(RecordingWindowing())
        presenter.show(Notice(id: "a", source: "ci", title: "a"), profiles: crawlProfiles(), actions: .inert)
        let key = CrawlPresenter.StripKey(displayID: 1, edge: .bottom)
        XCTAssertEqual(try XCTUnwrap(presenter.stripView(of: key)).itemAlpha, 0.4, accuracy: 0.001)
        presenter.remove(id: "a")
    }

    func testRulesDidChangeRelaysOutLiveStrips() throws {
        screens = [testScreen(1)]
        let windowing = RecordingWindowing()
        let presenter = makePresenter(windowing)
        presenter.show(Notice(id: "a", source: "ci", title: "a"), profiles: crawlProfiles(), actions: .inert)
        let bottom = CrawlPresenter.StripKey(displayID: 1, edge: .bottom)
        presenter.advance(by: 2)

        // A setting that only restyles keeps the strip and its place in the pass.
        rules.crawl.textSize = 24
        rules.crawl.leftToRight = true
        presenter.rulesDidChange()
        XCTAssertEqual(try XCTUnwrap(presenter.stripView(of: bottom)).textSize, 24)
        XCTAssertEqual(presenter.leftToRight(of: bottom), true)
        XCTAssertEqual(try XCTUnwrap(presenter.elapsed(of: bottom)), 2, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(windowing.presented.first).frame.height, 38)
        XCTAssertEqual(windowing.presented.count, 1)

        // A new edge moves the strip.
        rules.crawl.edge = .top
        presenter.rulesDidChange()
        XCTAssertNil(presenter.stripView(of: bottom))
        XCTAssertNotNil(presenter.stripView(of: CrawlPresenter.StripKey(displayID: 1, edge: .top)))
        XCTAssertEqual(windowing.dismissed.count, 1)
        XCTAssertEqual(presenter.shownIDs, ["a"])
        presenter.remove(id: "a")
    }

    func testStripCachesDirectionAndRestartsOnNewContent() throws {
        screens = [testScreen(1)]
        rules.crawl.leftToRight = true
        let presenter = makePresenter(RecordingWindowing())
        presenter.show(Notice(id: "a", source: "ci", title: "a"), profiles: profiles(.bottomLeft), actions: .inert)
        let key = CrawlPresenter.StripKey(displayID: 1, edge: .bottom)
        XCTAssertEqual(presenter.leftToRight(of: key), true)
        presenter.advance(by: 2)
        XCTAssertEqual(try XCTUnwrap(presenter.elapsed(of: key)), 2, accuracy: 0.001)

        rules.crawl.leftToRight = false
        XCTAssertEqual(presenter.leftToRight(of: key), true, "read once per refresh, not per frame")
        presenter.show(Notice(id: "b", source: "ci", title: "b"), profiles: profiles(.bottomLeft), actions: .inert)
        XCTAssertEqual(presenter.elapsed(of: key), 0, "new content starts its pass over")
        XCTAssertEqual(presenter.leftToRight(of: key), false)
        presenter.remove(id: "a")
        presenter.remove(id: "b")
    }

    func testScreenChangeRepositionsStrips() throws {
        screens = [testScreen(1)]
        let windowing = RecordingWindowing()
        let presenter = makePresenter(windowing)
        presenter.show(Notice(id: "a", source: "ci", title: "a"), profiles: profiles(.bottomCenter), actions: .inert)
        let panel = try XCTUnwrap(windowing.presented.first)
        XCTAssertEqual(panel.frame.width, 1512)

        screens = [testScreen(1, width: 2560)]
        presenter.screensDidChange()
        XCTAssertEqual(panel.frame.width, 2560)
        XCTAssertEqual(panel.frame.minY, screens[0].visibleFrame.minY)
        presenter.remove(id: "a")
    }
}
