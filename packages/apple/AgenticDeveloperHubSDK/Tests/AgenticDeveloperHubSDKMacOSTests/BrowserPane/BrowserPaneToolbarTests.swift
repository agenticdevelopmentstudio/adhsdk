import XCTest
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// An engine with a toolbar of its own (Chrome's) takes the navigation
/// controls' place, so the pane's bar keeps only its badges.
@MainActor
final class BrowserPaneToolbarTests: XCTestCase {

    private func makePane(ownToolbar: Bool) -> WebBrowserPaneViewController {
        let settings = UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider()
        )
        let pane = WebBrowserPaneViewController(
            makeEngine: { StubBrowserEngine(consoleLog: $0.consoleLog, providesOwnToolbar: ownToolbar) },
            engineKind: ownToolbar ? .chrome : .safari, minimizedSymbol: "globe",
            store: EphemeralPaneStateStore(), settings: settings, history: nil,
            homeURL: WebBrowserPaneViewController.blankPage)
        _ = pane.view
        return pane
    }

    private func navigation(_ pane: WebBrowserPaneViewController) -> [NSView] {
        [pane.addressField, pane.backButton, pane.forwardButton, pane.reloadButton]
    }

    func test_ownToolbarEngineHidesKitchenNavigation() throws {
        let pane = makePane(ownToolbar: true)
        XCTAssertTrue(navigation(pane).allSatisfy(\.isHidden))
        let bar = try XCTUnwrap(pane.addressBar)
        XCTAssertTrue(bar.arrangedSubviews.contains(pane.pausedBadge))
        XCTAssertTrue(bar.arrangedSubviews.contains(pane.drivenBadge))
    }

    /// What the bar shows: its arranged views that are not hidden, in order.
    private func shown(in bar: NSStackView) -> [NSView] {
        bar.arrangedSubviews.filter { !$0.isHidden }
    }

    /// Chrome's toolbar replaces the navigation controls, so the bar shows
    /// only the badges that are up, and is nothing at all when none is.
    func test_ownToolbarBarShowsOnlyShownBadges() throws {
        let pane = makePane(ownToolbar: true)
        let bar = try XCTUnwrap(pane.addressBar)
        XCTAssertTrue(pane.pausedBadge.isHidden)
        XCTAssertTrue(pane.drivenBadge.isHidden)
        XCTAssertEqual(shown(in: bar), [])

        pane.setEventsPaused(true)
        XCTAssertEqual(shown(in: bar), [pane.pausedBadge])
        pane.setEventsPaused(false)
        XCTAssertEqual(shown(in: bar), [])
    }

    /// The + is the pane's own (its tabs are Kitchen tabs), and it leads the
    /// tab row rather than the bar, whichever engine the pane runs.
    func test_newTabButtonLeadsTheTabRow() {
        for ownToolbar in [true, false] {
            let pane = makePane(ownToolbar: ownToolbar)
            let row = pane.newTabButton.superview as? TabBarView
            XCTAssertEqual(row?.edge, .top)
            XCTAssertFalse(pane.addressBar?.arrangedSubviews.contains(pane.newTabButton) ?? true)
        }
    }

    /// Tabs, then the address bar, then the page, top to bottom — the bar sits
    /// in the tab strip's slot below its tabs rather than above the strip.
    func test_addressBarSitsBetweenTheTabRowAndThePage() throws {
        let pane = makePane(ownToolbar: false)
        pane.view.frame = NSRect(x: 0, y: 0, width: 800, height: 600)
        pane.view.layoutSubtreeIfNeeded()
        let bar = try XCTUnwrap(pane.addressBar)
        let row = try XCTUnwrap(pane.newTabButton.superview as? TabBarView)
        // The pane's root is not flipped: a greater y is higher on screen.
        let rowFrame = pane.view.convert(row.bounds, from: row)
        let barFrame = pane.view.convert(bar.bounds, from: bar)
        let pageFrame = pane.view.convert(pane.engine.view.bounds, from: pane.engine.view)

        XCTAssertGreaterThan(barFrame.height, 0)
        XCTAssertLessThanOrEqual(barFrame.maxY, rowFrame.minY + 0.5, "the bar is under the tab row")
        XCTAssertLessThanOrEqual(pageFrame.maxY, barFrame.minY + 0.5, "the page is under the bar")
    }

    func test_refusalShowsInBarUntilNextNavigation() throws {
        let pane = makePane(ownToolbar: true)
        let bar = try XCTUnwrap(pane.addressBar)
        let engine = pane.engine
        let sentence = "Chrome settings are managed in Settings > Web Browser."

        pane.browserEngine(engine, didFailNavigationWith: ChromeNavigationPolicy.refusalError(
            sentence, address: "chrome://settings"))
        XCTAssertFalse(pane.refusalNotice.isHidden)
        XCTAssertEqual(pane.refusalNotice.stringValue, sentence)
        XCTAssertEqual(shown(in: bar), [pane.refusalNotice])

        pane.browserEngineDidStartNavigation(engine)
        XCTAssertTrue(pane.refusalNotice.isHidden)
        XCTAssertEqual(shown(in: bar), [])
    }

    /// Only the front tab moves the bar: a refusal reported by a tab behind
    /// it is not shown over the page in front.
    func test_refusalFromTabBehindIsNotShown() {
        let pane = makePane(ownToolbar: true)
        let behind = pane.engine
        pane.newTab(nil)
        XCTAssertFalse(pane.engine === behind, "the new tab is in front")
        let refusal = ChromeNavigationPolicy.refusalError(
            "Chrome settings are managed in Settings > Web Browser.", address: "chrome://settings")

        pane.browserEngine(behind, didFailNavigationWith: refusal)
        XCTAssertTrue(pane.refusalNotice.isHidden)

        pane.browserEngine(pane.engine, didFailNavigationWith: refusal)
        XCTAssertFalse(pane.refusalNotice.isHidden, "the front tab's refusal is shown")
    }

    func test_ordinaryLoadFailureShowsNoNotice() {
        let pane = makePane(ownToolbar: true)
        pane.browserEngine(pane.engine, didFailNavigationWith: URLError(.notConnectedToInternet))
        XCTAssertTrue(pane.refusalNotice.isHidden)
    }

    func test_safariKeepsKitchenNavigation() {
        let pane = makePane(ownToolbar: false)
        XCTAssertFalse(navigation(pane).contains(where: \.isHidden))
    }
}
