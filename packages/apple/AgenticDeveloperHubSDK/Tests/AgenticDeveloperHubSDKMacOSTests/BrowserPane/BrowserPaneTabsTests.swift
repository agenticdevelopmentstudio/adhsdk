import XCTest
import AppKit
import Combine
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// An engine that renders nothing and reports only what a test makes it
/// report, so the pane's tab handling can be driven without a web view.
@MainActor
final class FakeBrowserEngine: BrowserEngine {
    weak var delegate: BrowserEngineDelegate?
    let configuration: BrowserEngineConfiguration
    var url: URL?
    var title: String?
    var isLoading = false
    var loadingChanges: AnyPublisher<Bool, Never> { Empty().eraseToAnyPublisher() }
    let view = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 200))
    var viewportSize: CGSize { view.bounds.size }
    var canGoBack = false
    var canGoForward = false
    var consoleLog: BrowserConsoleLog { configuration.consoleLog }
    var inputGate = BrowserInputGate.open
    var onInputDecision: ((BrowserInputChannel, String, Bool, Bool, String) -> Void)?
    private(set) var isActivationShieldActive = false
    var heldLoadURL: URL? { nil }
    private(set) var loads: [URL] = []
    private(set) var isTornDown = false
    private(set) var isClosedByPage = false

    init(configuration: BrowserEngineConfiguration) {
        self.configuration = configuration
    }

    func load(_ url: URL) { loads.append(url) }
    func goBack() {}
    func goForward() {}
    func reload() {}
    func stopLoading() {}
    func teardown() {
        isTornDown = true
        delegate = nil
    }
    func setActivationShieldActive(_ active: Bool) { isActivationShieldActive = active }
    func applyCookiePolicy(acceptsCookies: Bool) {}
    func installAutomationRuntime() async throws {}
    func callAsyncFunction(body: String, arguments: [String: Any], world: BrowserScriptWorld) async throws -> Any? {
        nil
    }
    func snapshot(cssRect: CGRect?) async throws -> CGImage {
        throw CocoaError(.featureUnsupported)
    }
    func nativeClick(atViewportX viewportX: Double, viewportY: Double) async throws {}

    /// Commits `url` as the engine's page, as a real engine reports one.
    func commit(_ url: URL) {
        self.url = url
        delegate?.browserEngineDidStartNavigation(self)
        delegate?.browserEngineDidCommitNavigation(self)
        delegate?.browserEngineAddressDidChange(self)
        delegate?.browserEngineDidFinishNavigation(self)
    }

    /// The page calls `window.close()`. `destroysPage` is Chromium's way,
    /// whose browser is gone after it; WebKit's page only stops.
    func pageClosesItself(destroysPage: Bool = false) {
        isClosedByPage = destroysPage
        delegate?.browserEngineDidRequestClose(self)
    }
}

@MainActor
final class BrowserPaneTabsTests: XCTestCase {

    private var engines: [FakeBrowserEngine] = []
    private var store = EphemeralPaneStateStore()

    private func makeSettings() -> SettingsStore {
        UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider()
        )
    }

    private func makePane(settings: SettingsStore? = nil) -> WebBrowserPaneViewController {
        let pane = WebBrowserPaneViewController(
            makeEngine: { [unowned self] configuration in
                let engine = FakeBrowserEngine(configuration: configuration)
                engines.append(engine)
                return engine
            },
            engineKind: .safari,
            minimizedSymbol: "safari",
            store: store,
            settings: settings ?? makeSettings(),
            history: nil,
            homeURL: WebBrowserPaneViewController.blankPage
        )
        _ = pane.view
        return pane
    }

    private var storedTabs: StoredBrowserTabs {
        WebBrowserPaneViewController.readStoredTabs(from: store)
    }

    // MARK: - Media capture

    func testABackgroundTabsMediaRequestIsRefusedNotAskedOverTheFrontTab() async {
        let pane = makePane()
        let background = engines[0]
        pane.newTab(nil)
        XCTAssertTrue(pane.engine !== background, "the new tab is in front")

        let answer = await pane.browserEngine(background, allowsMediaCaptureFor: "example.com", device: "camera")
        XCTAssertEqual(answer, false, "a hidden tab is never granted, nor asked about over another page")
    }

    func testTheFrontTabsMediaRequestStillReachesTheQuestion() async {
        let pane = makePane()
        pane.newTab(nil)
        // No window to ask on: the answer is left to the engine, as before.
        let answer = await pane.browserEngine(pane.engine, allowsMediaCaptureFor: "example.com", device: "camera")
        XCTAssertNil(answer)
    }

    func testAnAllowSettingStillAppliesToABackgroundTab() async {
        let settings = makeSettings()
        settings.set(BrowserMediaCapturePolicy.allow, for: UserSettings.browserMediaCapture)
        let pane = makePane(settings: settings)
        let background = engines[0]
        pane.newTab(nil)
        let answer = await pane.browserEngine(background, allowsMediaCaptureFor: "example.com", device: "camera")
        XCTAssertEqual(answer, true, "no question is shown, so nothing is shown over the wrong tab")
    }

    // MARK: - window.close()

    private let page = URL(string: "https://example.com/inbox")!

    func testAPageCannotCloseThePanesOnlyTab() throws {
        let pane = makePane()
        let only = engines[0]
        only.commit(page)
        only.pageClosesItself()
        XCTAssertFalse(only.isTornDown)
        XCTAssertTrue(pane.engine === only, "the page was only stopped; it stays")
        XCTAssertEqual(engines.count, 1)
        XCTAssertEqual(storedTabs.tabs.map(\.url), [page.absoluteString], "the tab keeps its page")
    }

    func testAPageCannotCloseATabTheUserOpened() throws {
        let pane = makePane()
        pane.newTab(nil)
        let opened = engines[1]
        opened.commit(page)
        opened.pageClosesItself()
        XCTAssertFalse(opened.isTornDown)
        XCTAssertEqual(storedTabs.tabs.count, 2)
        XCTAssertTrue(pane.engine === opened)
    }

    func testAPopupsPageClosesItsTabAndTheOpenerComesBack() throws {
        let pane = makePane()
        let opener = engines[0]
        opener.commit(page)
        let popup = FakeBrowserEngine(configuration: opener.configuration)
        XCTAssertTrue(pane.browserEngine(opener, didOpenPopup: popup))
        XCTAssertTrue(pane.engine === popup)
        XCTAssertEqual(storedTabs.tabs.count, 2)

        popup.pageClosesItself()
        XCTAssertTrue(popup.isTornDown)
        XCTAssertEqual(storedTabs.tabs.count, 1)
        XCTAssertTrue(pane.engine === opener)
    }

    func testAnIgnoredCloseThatDestroyedThePageGetsANewEngineOnTheSamePage() throws {
        let pane = makePane()
        let only = engines[0]
        only.commit(page)
        only.pageClosesItself(destroysPage: true)
        XCTAssertTrue(only.isTornDown, "Chromium's browser is gone; the engine is replaced")
        let revived = try XCTUnwrap(engines.last)
        XCTAssertTrue(revived !== only)
        XCTAssertTrue(pane.engine === revived)
        XCTAssertEqual(revived.loads, [page], "the tab reopens on the page it showed")
        XCTAssertEqual(storedTabs.tabs.map(\.url), [page.absoluteString])
    }
}
