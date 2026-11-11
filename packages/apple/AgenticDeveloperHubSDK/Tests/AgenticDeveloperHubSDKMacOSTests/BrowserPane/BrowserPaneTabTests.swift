import AppKit
import Combine
import XCTest
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// An engine that loads nothing: the test sets its page and title and tells
/// the pane what happened, as a real engine's callbacks would.
@MainActor
private final class ScriptedBrowserEngine: BrowserEngine {
    weak var delegate: BrowserEngineDelegate?
    var url: URL?
    var title: String?
    var isLoading = false
    var loadingChanges: AnyPublisher<Bool, Never> { Just(false).eraseToAnyPublisher() }
    let view = NSView()
    var viewportSize: CGSize { .zero }
    var canGoBack = false
    var canGoForward = false
    let consoleLog: BrowserConsoleLog
    var inputGate = BrowserInputGate.open
    var onInputDecision: ((BrowserInputChannel, String, Bool, Bool, String) -> Void)?
    var isActivationShieldActive = false
    var heldLoadURL: URL?
    private(set) var isTornDown = false

    init(consoleLog: BrowserConsoleLog) { self.consoleLog = consoleLog }

    func load(_ url: URL) {}
    func goBack() {}
    func goForward() {}
    func reload() {}
    func stopLoading() {}
    func teardown() { isTornDown = true }
    func setActivationShieldActive(_ active: Bool) { isActivationShieldActive = active }
    func applyCookiePolicy(acceptsCookies: Bool) {}
    func installAutomationRuntime() async throws {}
    func callAsyncFunction(body: String, arguments: [String: Any], world: BrowserScriptWorld) async throws -> Any? {
        nil
    }
    func snapshot(cssRect: CGRect?) async throws -> CGImage { throw CancellationError() }
    func nativeClick(atViewportX viewportX: Double, viewportY: Double) async throws {}

    /// The page `url`, titled `title`, committed and finished.
    func show(_ url: URL, titled title: String) {
        self.url = url
        self.title = title
        delegate?.browserEngineDidCommitNavigation(self)
        delegate?.browserEngineTitleDidChange(self)
        delegate?.browserEngineDidFinishNavigation(self)
    }
}

@MainActor
final class BrowserPaneTabTests: XCTestCase {
    private var engines: [ScriptedBrowserEngine] = []
    private var store: EphemeralPaneStateStore!

    override func setUp() async throws {
        try await super.setUp()
        engines = []
        store = EphemeralPaneStateStore()
    }

    private func makePane(storedTabs: StoredBrowserTabs? = nil) throws -> WebBrowserPaneViewController {
        if let storedTabs {
            let json = try XCTUnwrap(String(data: JSONEncoder().encode(storedTabs), encoding: .utf8))
            store.setPaneStateValue(json, forKey: WebBrowserPaneViewController.tabsKey)
        }
        let pane = WebBrowserPaneViewController(
            makeEngine: { [unowned self] configuration in
                let made = ScriptedBrowserEngine(consoleLog: configuration.consoleLog)
                engines.append(made)
                return made
            },
            engineKind: .safari,
            minimizedSymbol: "safari",
            store: store,
            settings: UserSettings(
                with: InMemorySettingsStorageProvider(),
                secureSettingsProvider: InMemorySecureSettingsStorageProvider()),
            history: nil,
            homeURL: WebBrowserPaneViewController.blankPage
        )
        _ = pane.view
        return pane
    }

    private var storedTabs: StoredBrowserTabs { WebBrowserPaneViewController.readStoredTabs(from: store) }

    private func frontEngine(of pane: WebBrowserPaneViewController) throws -> ScriptedBrowserEngine {
        try XCTUnwrap(pane.engine as? ScriptedBrowserEngine)
    }

    private let pageA = URL(string: "https://a.example/")!
    private let pageB = URL(string: "https://b.example/")!

    private var twoStoredTabs: StoredBrowserTabs {
        StoredBrowserTabs(
            tabs: [StoredBrowserTab(url: pageA.absoluteString, title: "A"),
                   StoredBrowserTab(url: pageB.absoluteString, title: "B")],
            selectedIndex: 0)
    }

    // MARK: - A rebuild keeps every tab's name

    func testARebuildKeepsTheNameOfATabBehindTheFrontOne() throws {
        let pane = try makePane(storedTabs: twoStoredTabs)
        XCTAssertEqual(engines.count, 2)
        // Tab B has loaded its page once, which drops the name it was stored under.
        engines[1].show(pageB, titled: "Bee")
        engines[0].show(pageA, titled: "Ay")

        pane.rebuildEngine()
        XCTAssertEqual(engines.count, 4)
        // The front tab's new engine commits its page, which stores the tab list.
        try frontEngine(of: pane).show(pageA, titled: "Ay")

        XCTAssertEqual(storedTabs.tabs.map(\.title), ["Ay", "Bee"])
        XCTAssertEqual(storedTabs.tabs.map(\.url), [pageA.absoluteString, pageB.absoluteString])
    }

    func testARebuildKeepsTheStoredNameOfATabNeverBroughtForward() throws {
        let pane = try makePane(storedTabs: twoStoredTabs)
        engines[0].show(pageA, titled: "Ay")
        pane.rebuildEngine()
        try frontEngine(of: pane).show(pageA, titled: "Ay")
        XCTAssertEqual(storedTabs.tabs.map(\.title), ["Ay", "B"])
    }
}
