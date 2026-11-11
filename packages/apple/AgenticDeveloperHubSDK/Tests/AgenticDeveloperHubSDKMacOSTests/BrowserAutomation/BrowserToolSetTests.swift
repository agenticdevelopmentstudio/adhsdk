// swiftlint:disable line_length force_try force_cast
import XCTest
import WebKit
@testable import AgenticDeveloperHubSDKMacOS
@testable import AgenticDeveloperHubSDKCore

@MainActor
final class FakeBrowserDirectory: BrowserPaneDirectory {
    var panes: [BrowserPaneHandle] = []
    var beside: [String: String] = [:]      // caller pane id -> browser pane id
    var lastUsed: String?
    var opened: [String?] = []
    var openedEngines: [BrowserEngineKind] = []
    var openFails = false
    /// The Agent access a pane this directory opens comes with.
    var openAccess: BrowserAgentAccess = .full
    /// Every pane id the tool set asked to reveal, in order.
    var revealed: [String] = []
    /// Every pane id the tool set asked to close, in order.
    var closed: [String] = []
    let pages: [String: OffscreenWebView]

    init(pages: [String: OffscreenWebView]) { self.pages = pages }

    func browserPanes() -> [BrowserPaneHandle] { panes }
    func browserPane(id: String) -> BrowserPaneHandle? { panes.first { $0.id == id } }
    func browserPane(besidePane paneID: String) -> BrowserPaneHandle? { beside[paneID].flatMap(browserPane(id:)) }
    func lastUsedBrowserPane() -> BrowserPaneHandle? { lastUsed.flatMap(browserPane(id:)) }
    func openBrowserPane(besidePane paneID: String?, engine: BrowserEngineKind) throws -> BrowserPaneHandle {
        opened.append(paneID)
        openedEngines.append(engine)
        if openFails { throw BrowserAutomationError.openRefused }
        let page = OffscreenWebView()
        let handle = BrowserPaneHandle(id: "new-\(panes.count)", project: "proj", tab: "Tab", automation: BrowserAutomation(webView: page.webView, console: BrowserConsoleLog()), engine: engine, access: openAccess)
        panes.append(handle)
        return handle
    }
    func revealBrowserPane(id: String) { revealed.append(id) }
    func closeBrowserPane(id: String) {
        closed.append(id)
        panes.removeAll { $0.id == id }
    }
}

@MainActor
final class BrowserToolSetTests: XCTestCase {

    private var store: UserSettings!
    private var directory: FakeBrowserDirectory!
    private var tools: BrowserToolSet!
    private var pages: [String: OffscreenWebView] = [:]

    override func setUp() async throws {
        store = UserSettings(with: InMemorySettingsStorageProvider(), secureSettingsProvider: InMemorySecureSettingsStorageProvider())
        pages = ["A": OffscreenWebView(), "B": OffscreenWebView()]
        await pages["A"]!.load(html: "<title>Alpha</title><button>One</button>")
        await pages["B"]!.load(html: "<title>Beta</title><a href=\"/x\">Two</a>")
        directory = FakeBrowserDirectory(pages: pages)
        for (id, page) in pages.sorted(by: { $0.key < $1.key }) {
            directory.panes.append(BrowserPaneHandle(id: id, project: "proj", tab: "Tab \(id)", automation: BrowserAutomation(webView: page.webView, console: BrowserConsoleLog())))
        }
        tools = BrowserToolSet(directory: directory, settings: store)
    }

    private func call(_ name: String, _ args: [String: Any] = [:], caller: String? = nil) async -> (content: String, isError: Bool) {
        let data = try! JSONSerialization.data(withJSONObject: args)
        return await tools.callTool(name: name, argumentsJSON: data, caller: caller)
    }

    func testAdvertisesTwentyToolsWithObjectSchemas() async {
        let defs = await tools.toolDefinitions()
        XCTAssertEqual(defs.count, 20)
        XCTAssertEqual(Set(defs.map(\.name)), Set(BrowserToolSet.toolNames))
        for def in defs {
            let schema = try! JSONSerialization.jsonObject(with: def.parametersJSONSchema) as! [String: Any]
            XCTAssertEqual(schema["type"] as? String, "object", def.name)
            XCTAssertFalse(def.description.isEmpty, def.name)
        }
    }

    func testListNamesEveryPaneAndTheDefault() async {
        directory.lastUsed = "B"
        let reply = await call("browser_list")
        XCTAssertFalse(reply.isError)
        let rows = try! JSONSerialization.jsonObject(with: Data(reply.content.utf8)) as! [[String: Any]]
        XCTAssertEqual(rows.map { $0["id"] as? String }, ["A", "B"])
        XCTAssertEqual(rows.map { $0["title"] as? String }, ["Alpha", "Beta"])
        XCTAssertEqual(rows.map { $0["is_default"] as? Bool }, [false, true])
        XCTAssertEqual(rows.map { $0["engine"] as? String }, ["safari", "safari"])
    }

    func testDefaultPaneIsBesideCallerThenLastUsedThenFirst() async {
        directory.beside["term-1"] = "B"
        directory.lastUsed = "A"
        let beside = await call("browser_snapshot", caller: "term-1")
        XCTAssertTrue(beside.content.contains("Two"), beside.content)
        let lastUsed = await call("browser_snapshot", caller: "term-9")
        XCTAssertTrue(lastUsed.content.contains("One"), lastUsed.content)
        directory.lastUsed = nil
        let first = await call("browser_snapshot")
        XCTAssertTrue(first.content.contains("One"), first.content)
    }

    func testExplicitPaneIDWins() async {
        directory.lastUsed = "A"
        let reply = await call("browser_snapshot", ["pane_id": "B"])
        XCTAssertTrue(reply.content.contains("Two"), reply.content)
    }

    func testClosedPaneIsASentence() async {
        let reply = await call("browser_snapshot", ["pane_id": "gone"])
        XCTAssertTrue(reply.isError)
        XCTAssertEqual(reply.content, "pane gone was closed; call browser_list")
    }

    func testNoPaneIsASentence() async {
        directory.panes.removeAll()
        let reply = await call("browser_snapshot")
        XCTAssertTrue(reply.isError)
        XCTAssertEqual(reply.content, "no browser pane is open; call browser_open")
    }

    func testOpenAsksTheDirectoryBesideTheCaller() async {
        let reply = await call("browser_open", ["url": "about:blank"], caller: "term-1")
        XCTAssertFalse(reply.isError, reply.content)
        XCTAssertEqual(directory.opened, ["term-1"])
        XCTAssertEqual(directory.openedEngines, [.safari])
        XCTAssertTrue(reply.content.contains("new-2"))
    }

    /// Chrome is one argument away and otherwise the same open: the engine
    /// is the only difference a model sees, and browser_list reports it.
    func testOpenTakesTheEngine() async throws {
        let reply = await call("browser_open", ["url": "about:blank", "engine": "chrome"], caller: "term-1")
        XCTAssertFalse(reply.isError, reply.content)
        XCTAssertEqual(directory.openedEngines, [.chrome])
        let list = await call("browser_list")
        let rows = try XCTUnwrap(try JSONSerialization.jsonObject(with: Data(list.content.utf8)) as? [[String: Any]])
        XCTAssertEqual(rows.last?["engine"] as? String, "chrome")
    }

    func testOpenRefusesAnUnknownEngine() async {
        let reply = await call("browser_open", ["url": "about:blank", "engine": "gecko"])
        XCTAssertTrue(reply.isError)
        XCTAssertEqual(reply.content, "browser_open engine must be safari or chrome, not gecko")
        XCTAssertTrue(directory.opened.isEmpty)
    }

    /// The URL is optional: with none given the pane opens on the Home Page
    /// setting, and with that blank (as it is here) on a blank page.
    func testOpenWithoutAURLOpensABlankPage() async throws {
        let reply = await call("browser_open", caller: "term-1")
        XCTAssertFalse(reply.isError, reply.content)
        XCTAssertTrue(reply.content.hasPrefix("opened pane new-2"), reply.content)
        XCTAssertEqual(directory.panes.last?.automation.currentURL, "about:blank")
        let open = try XCTUnwrap(BrowserToolSet.definitions.first { $0.name == "browser_open" })
        let schema = try XCTUnwrap(try JSONSerialization.jsonObject(with: open.parametersJSONSchema) as? [String: Any])
        XCTAssertFalse((schema["required"] as? [String] ?? []).contains("url"))
    }

    func testAFailedOpenIsTheSentence() async {
        directory.openFails = true
        let reply = await call("browser_open", ["url": "about:blank"], caller: "term-1")
        XCTAssertTrue(reply.isError)
        XCTAssertEqual(reply.content, "could not open a Browser pane beside that pane")
    }

    func testOpenRefusesNonHTTP() async {
        let reply = await call("browser_open", ["url": "file:///etc/passwd"])
        XCTAssertTrue(reply.isError)
        XCTAssertEqual(reply.content, "only http and https URLs can be opened")
        XCTAssertTrue(directory.opened.isEmpty)
    }

    func testNavigateRefusesNonHTTP() async {
        let reply = await call("browser_navigate", ["url": "javascript:alert(1)"])
        XCTAssertTrue(reply.isError)
        XCTAssertEqual(reply.content, "only http and https URLs can be opened")
    }

    func testFilePaneIsRefused() async {
        let page = OffscreenWebView()
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("local-\(UUID().uuidString).html")
        defer { try? FileManager.default.removeItem(at: url) }
        try! "<p>local</p>".write(to: url, atomically: true, encoding: .utf8)
        await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in
            page.webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { done.resume() }
        }
        directory.panes = [BrowserPaneHandle(id: "F", project: "p", tab: "t", automation: BrowserAutomation(webView: page.webView, console: BrowserConsoleLog()))]
        let reply = await call("browser_snapshot")
        XCTAssertTrue(reply.isError)
        XCTAssertEqual(reply.content, "pane F shows a local file, which models may not drive")
    }

    /// A call queued behind another is checked again when it runs: the switch
    /// flipped off meanwhile refuses it.
    func testSwitchTurnedOffWhileQueuedRefusesTheQueuedCall() async throws {
        let automation = directory.panes[0].automation
        let store = self.store!
        let held = Task { @MainActor in
            try await automation.drive {
                try await Task.sleep(nanoseconds: 300_000_000)
                store.set(false, for: UserSettings.browserAutomationEnabled)
            }
        }
        try await Task.sleep(nanoseconds: 50_000_000)
        let reply = await call("browser_snapshot", ["pane_id": "A"])
        _ = try await held.value
        XCTAssertTrue(reply.isError)
        XCTAssertEqual(reply.content, "browser automation is turned off in Settings")
    }

    /// A pane that once showed a local file, then a page: a back that lands
    /// on the file is refused, and nothing is read from it.
    func testBackOntoALocalFileIsRefused() async throws {
        let page = OffscreenWebView()
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("local-\(UUID().uuidString).html")
        defer { try? FileManager.default.removeItem(at: url) }
        try "<p>local</p>".write(to: url, atomically: true, encoding: .utf8)
        let failure = await page.load(fileURL: url)
        XCTAssertNil(failure, "the local file never loaded: \(String(describing: failure))")
        await page.navigate(to: URL(string: "https://web.test/")!, html: "<title>Web</title><p>web</p>")
        XCTAssertEqual(page.webView.backForwardList.backItem?.url.isFileURL, true,
                       "nothing to go back to: \(String(describing: page.webView.backForwardList.backItem?.url))")
        directory.panes = [BrowserPaneHandle(id: "F", project: "p", tab: "t", automation: BrowserAutomation(webView: page.webView, console: BrowserConsoleLog()))]
        let back = await call("browser_back")
        XCTAssertTrue(back.isError)
        XCTAssertEqual(back.content, "the pane shows a local file, which models may not drive")
        let text = await call("browser_text")
        XCTAssertTrue(text.isError)
        XCTAssertEqual(text.content, "pane F shows a local file, which models may not drive")
    }

    func testAutomationOffLeavesOnlyList() async {
        store.set(false, for: UserSettings.browserAutomationEnabled)
        let list = await call("browser_list")
        XCTAssertFalse(list.isError)
        let snap = await call("browser_snapshot")
        XCTAssertTrue(snap.isError)
        XCTAssertEqual(snap.content, "browser automation is turned off in Settings")
    }

    func testEvaluateIsOffByDefaultAndOnWhenEnabled() async {
        let off = await call("browser_evaluate", ["expression": "1+1"])
        XCTAssertTrue(off.isError)
        XCTAssertEqual(off.content, "browser_evaluate is turned off in Settings")
        store.set(true, for: UserSettings.browserAutomationEvaluate)
        let enabled = await call("browser_evaluate", ["expression": "1+1"])
        XCTAssertFalse(enabled.isError)
        XCTAssertEqual(enabled.content, "2")
    }

    func testMalformedArgumentsAreASentence() async {
        let reply = await tools.callTool(name: "browser_click", argumentsJSON: Data("{not json".utf8), caller: nil)
        XCTAssertTrue(reply.isError)
        XCTAssertEqual(reply.content, "browser_click arguments are not valid JSON")
    }

    func testMissingRefIsASentence() async {
        let reply = await call("browser_click", ["generation": 1])
        XCTAssertTrue(reply.isError)
        XCTAssertEqual(reply.content, "browser_click needs ref")
    }

    /// `value` is required; a number must not fill in "" and report success.
    func testFillWithANumericValueIsASentence() async {
        let reply = await call("browser_fill", ["pane_id": "A", "ref": "e1", "generation": 1, "value": 42])
        XCTAssertTrue(reply.isError)
        XCTAssertEqual(reply.content, "browser_fill needs value as a string")
    }

    func testFillWithoutAValueIsASentence() async {
        let reply = await call("browser_fill", ["pane_id": "A", "ref": "e1", "generation": 1])
        XCTAssertTrue(reply.isError)
        XCTAssertEqual(reply.content, "browser_fill needs value as a string")
    }

    func testClickAtBeforeAScreenshotIsASentence() async {
        let reply = await call("browser_click_at", ["pane_id": "A", "x": 5, "y": 5])
        XCTAssertTrue(reply.isError)
        XCTAssertEqual(reply.content, "take a browser_screenshot first; browser_click_at reads its coordinates off that image")
    }

    func testUnknownToolIsASentence() async {
        let reply = await call("browser_fly")
        XCTAssertTrue(reply.isError)
        XCTAssertEqual(reply.content, "unknown tool browser_fly")
    }

    func testClickAfterSnapshotReturnsADelta() async {
        let snap = await call("browser_snapshot", ["pane_id": "A"])
        let gen = Int(snap.content.components(separatedBy: "generation: ").last!.components(separatedBy: "\n").first!)!
        let reply = await call("browser_click", ["pane_id": "A", "ref": "e1", "generation": gen])
        XCTAssertFalse(reply.isError, reply.content)
        XCTAssertTrue(reply.content.contains("no visible change"))
    }

    func testStaleRefIsTheSentence() async {
        _ = await call("browser_snapshot", ["pane_id": "A"])
        let reply = await call("browser_click", ["pane_id": "A", "ref": "e1", "generation": 0])
        XCTAssertTrue(reply.isError)
        XCTAssertEqual(reply.content, "stale ref; take a new snapshot")
    }

    func testNonIntegerGenerationIsASentence() async {
        let reply = await tools.callTool(name: "browser_click", argumentsJSON: Data("{\"ref\":\"e1\",\"generation\":1e30}".utf8), caller: nil)
        XCTAssertTrue(reply.isError)
        XCTAssertEqual(reply.content, "browser_click needs generation")
    }

    func testScreenshotRefWithoutGenerationIsASentence() async {
        let reply = await call("browser_screenshot", ["pane_id": "A", "ref": "e1"])
        XCTAssertTrue(reply.isError)
        XCTAssertEqual(reply.content, "browser_screenshot needs generation")
    }

    func testEmptyPaneIDMeansTheDefaultPane() async {
        directory.lastUsed = "B"
        let reply = await call("browser_snapshot", ["pane_id": ""])
        XCTAssertTrue(reply.content.contains("Two"), reply.content)
    }

    func testEvaluateOffSaysSoEvenWithNoPane() async {
        directory.panes.removeAll()
        let reply = await call("browser_evaluate", ["expression": "1+1"])
        XCTAssertTrue(reply.isError)
        XCTAssertEqual(reply.content, "browser_evaluate is turned off in Settings")
    }

    func testConsoleSaysWhenCaptureIsOff() async {
        directory.panes[0].automation.isConsoleCaptureOn = false
        let reply = await call("browser_console", ["pane_id": "A"])
        XCTAssertFalse(reply.isError, reply.content)
        XCTAssertEqual(reply.content, "Console capture is off for this pane.")
        let other = await call("browser_console", ["pane_id": "B"])
        XCTAssertEqual(other.content, "no console messages")
    }

    func testScreenshotReturnsAnImageDataURL() async {
        pages["A"]!.orderInOffscreen()
        let reply = await call("browser_screenshot", ["pane_id": "A"])
        XCTAssertFalse(reply.isError, reply.content)
        XCTAssertTrue(reply.content.hasPrefix("data:image/png;base64,"))
    }

    // MARK: Agent access

    /// The handle for page `id` with the given access and pause state.
    private func handle(_ id: String, access: BrowserAgentAccess = .full, pausedForAgent: Bool = false) -> BrowserPaneHandle {
        BrowserPaneHandle(id: id, project: "proj", tab: "Tab \(id)", automation: directory.panes.first { $0.id == id }!.automation, access: access, isPausedForAgent: pausedForAgent)
    }

    func testHiddenPaneIsNotListed() async {
        directory.panes = FakeBrowserDirectory.visible([handle("A"), handle("B", access: .hidden)])
        let list = await call("browser_list")
        let rows = try! JSONSerialization.jsonObject(with: Data(list.content.utf8)) as! [[String: Any]]
        XCTAssertEqual(rows.map { $0["id"] as? String }, ["A"])
        let byID = await call("browser_snapshot", ["pane_id": "B"])
        XCTAssertTrue(byID.isError)
        XCTAssertEqual(byID.content, "pane B was closed; call browser_list")
        let byDefault = await call("browser_snapshot")
        XCTAssertTrue(byDefault.content.contains("One"), byDefault.content)
    }

    func testReadOnlyPaneRefusesClick() async {
        directory.panes = [handle("A", access: .readOnly), handle("B")]
        let snap = await call("browser_snapshot", ["pane_id": "A"])
        XCTAssertFalse(snap.isError, snap.content)
        for (tool, args) in [
            ("browser_click", ["ref": "e1", "generation": 1] as [String: Any]),
            ("browser_navigate", ["url": "https://example.test/"]),
            ("browser_press_key", ["key": "Enter"]),
            ("browser_scroll", [:])
        ] {
            let reply = await call(tool, args.merging(["pane_id": "A"]) { $1 })
            XCTAssertTrue(reply.isError, tool)
            XCTAssertEqual(reply.content, "This browser pane is read only for the agent (Settings > Session Privacy > Agent access).", tool)
        }
        store.set(true, for: UserSettings.browserAutomationEvaluate)
        let evaluate = await call("browser_evaluate", ["pane_id": "A", "expression": "1+1"])
        XCTAssertEqual(evaluate.content, "This browser pane is read only for the agent (Settings > Session Privacy > Agent access).")
        let other = await call("browser_click", ["pane_id": "B", "ref": "e1", "generation": 99])
        XCTAssertNotEqual(other.content, "This browser pane is read only for the agent (Settings > Session Privacy > Agent access).")
    }

    func testReadOnlyPaneAllowsSnapshot() async {
        directory.panes = [handle("A", access: .readOnly), handle("B")]
        let snap = await call("browser_snapshot", ["pane_id": "A"])
        XCTAssertFalse(snap.isError, snap.content)
        XCTAssertTrue(snap.content.contains("One"), snap.content)
        let find = await call("browser_find", ["pane_id": "A", "text": "one"])
        XCTAssertFalse(find.isError, find.content)
        let text = await call("browser_text", ["pane_id": "A"])
        XCTAssertFalse(text.isError, text.content)
        let console = await call("browser_console", ["pane_id": "A"])
        XCTAssertFalse(console.isError, console.content)
        let wait = await call("browser_wait_for", ["pane_id": "A", "text": "One", "timeout": 1])
        XCTAssertFalse(wait.isError, wait.content)
    }

    func testPausedForAgentRefusesSnapshot() async {
        directory.panes = [handle("A", pausedForAgent: true), handle("B")]
        for tool in ["browser_snapshot", "browser_text", "browser_back"] {
            let reply = await call(tool, ["pane_id": "A"])
            XCTAssertTrue(reply.isError, tool)
            XCTAssertEqual(reply.content, "This browser pane's events are paused, and its settings pause the agent too.", tool)
        }
        let list = await call("browser_list")
        XCTAssertFalse(list.isError, list.content)
    }

    /// The handle is read again once the call is dequeued: a pane made read
    /// only while the call waited refuses it. The click is seen waiting at
    /// the gate before access changes, so it passed the check before the
    /// queue, and the refusal can only come from the check after it.
    func testAccessChangedWhileQueuedRefusesTheQueuedCall() async throws {
        let automation = directory.panes[0].automation
        let (release, releaser) = AsyncStream.makeStream(of: Void.self)
        let held = Task { @MainActor in
            try await automation.drive {
                for await _ in release { break }
            }
        }
        try await waitUntil("the holder has the gate") { automation.isActionInFlight }
        let click = Task { await self.call("browser_click", ["pane_id": "A", "ref": "e1", "generation": 1]) }
        try await waitUntil("the click is queued") { automation.queuedCallCount == 1 }
        directory.panes[0] = handle("A", access: .readOnly)
        releaser.yield()
        releaser.finish()
        _ = try await held.value
        let reply = await click.value
        XCTAssertTrue(reply.isError)
        XCTAssertEqual(reply.content, "This browser pane is read only for the agent (Settings > Session Privacy > Agent access).")
        XCTAssertEqual(directory.revealed, ["A"], "revealed once, when the click passed the check before the queue")
    }

    /// Yields the main actor until `condition` holds; fails after a bounded
    /// number of turns rather than hanging.
    private func waitUntil(_ what: String, _ condition: () -> Bool) async throws {
        for _ in 0..<10_000 {
            if condition() { return }
            await Task.yield()
        }
        XCTFail("never: \(what)")
        throw CancellationError()
    }

    /// A refused call reveals nothing: neither the read-only pane named by
    /// id, nor the paused one reached as the default, nor the one beside the
    /// caller. A call that passes reveals its pane.
    func testRefusedCallRevealsNothing() async {
        directory.panes = [handle("A", access: .readOnly), handle("B", pausedForAgent: true)]
        directory.beside["term-1"] = "A"
        directory.lastUsed = "B"
        let byID = await call("browser_click", ["pane_id": "A", "ref": "e1", "generation": 1])
        XCTAssertTrue(byID.isError)
        let beside = await call("browser_press_key", ["key": "Enter"], caller: "term-1")
        XCTAssertTrue(beside.isError)
        let lastUsed = await call("browser_snapshot")
        XCTAssertTrue(lastUsed.isError)
        XCTAssertEqual(directory.revealed, [])
        let allowed = await call("browser_snapshot", ["pane_id": "A"])
        XCTAssertFalse(allowed.isError, allowed.content)
        XCTAssertEqual(directory.revealed, ["A"])
    }

    /// An open whose new pane refuses the agent closes that pane again and
    /// says only that the open was refused, whatever the reason.
    func testRefusedOpenLeavesNoPane() async {
        for access in [BrowserAgentAccess.hidden, .readOnly] {
            directory.openAccess = access
            let before = directory.panes.map(\.id)
            let reply = await call("browser_open", ["url": "https://example.test/"], caller: "term-1")
            XCTAssertTrue(reply.isError, "\(access)")
            XCTAssertEqual(reply.content, "could not open a Browser pane beside that pane", "\(access)")
            XCTAssertEqual(directory.panes.map(\.id), before, "\(access)")
            XCTAssertEqual(directory.revealed, [], "\(access)")
        }
        XCTAssertEqual(directory.closed.count, 2)
    }

    func testListPanesReportsAccess() async {
        directory.panes = [handle("A", access: .readOnly), handle("B")]
        let reply = await call("browser_list")
        let rows = try! JSONSerialization.jsonObject(with: Data(reply.content.utf8)) as! [[String: Any]]
        XCTAssertEqual(rows.map { $0["access"] as? String }, ["read only", "full"])
    }

    func testFindAndTextAndWait() async {
        let find = await call("browser_find", ["pane_id": "B", "text": "two"])
        XCTAssertTrue(find.content.contains("e1"), find.content)
        let text = await call("browser_text", ["pane_id": "B"])
        XCTAssertEqual(text.content.trimmingCharacters(in: .whitespacesAndNewlines), "Two")
        let wait = await call("browser_wait_for", ["pane_id": "B", "text": "Two", "timeout": 1])
        XCTAssertFalse(wait.isError, wait.content)
        let timeout = await call("browser_wait_for", ["pane_id": "B", "text": "never", "timeout": 0.2])
        XCTAssertTrue(timeout.isError)
        XCTAssertEqual(timeout.content, "timed out waiting for text \"never\"")
    }

    // MARK: Agent Privacy

    /// Page B ("Beta", a "Two" link) is shown to models as "Gamma" and "Zwei".
    private let privateWords = TextSubstitutionFilter(pairs: [
        .init(alias: "Gamma", real: "Beta"), .init(alias: "Zwei", real: "Two")
    ])

    private func privateHandle(_ id: String, _ privacy: BrowserAgentPrivacy) -> BrowserPaneHandle {
        BrowserPaneHandle(id: id, project: "proj", tab: "Tab \(id)", automation: directory.panes.first { $0.id == id }!.automation, agentPrivacy: privacy)
    }

    func testAgentPrivacyConcealsWhatAModelReads() async {
        directory.panes = [handle("A"), privateHandle("B", .enabled(privateWords))]
        let snap = await call("browser_snapshot", ["pane_id": "B"])
        XCTAssertFalse(snap.isError, snap.content)
        XCTAssertTrue(snap.content.contains("Zwei") && snap.content.contains("Gamma"), snap.content)
        XCTAssertFalse(snap.content.contains("Two") || snap.content.contains("Beta"), snap.content)
        let text = await call("browser_text", ["pane_id": "B"])
        XCTAssertEqual(text.content.trimmingCharacters(in: .whitespacesAndNewlines), "Zwei")
        let other = await call("browser_text", ["pane_id": "A"])
        XCTAssertEqual(other.content.trimmingCharacters(in: .whitespacesAndNewlines), "One")
    }

    func testAgentPrivacyRevealsWhatAModelSends() async {
        directory.panes = [handle("A"), privateHandle("B", .enabled(privateWords))]
        let find = await call("browser_find", ["pane_id": "B", "text": "zwei"])
        XCTAssertFalse(find.isError, find.content)
        XCTAssertTrue(find.content.contains("e1") && find.content.contains("Zwei"), find.content)
        XCTAssertFalse(find.content.contains("Two"), find.content)
        let wait = await call("browser_wait_for", ["pane_id": "B", "text": "Zwei", "timeout": 1])
        XCTAssertFalse(wait.isError, wait.content)
    }

    func testAgentPrivacyConcealsErrors() async {
        directory.panes = [handle("A"), privateHandle("B", .enabled(privateWords))]
        let reply = await call("browser_wait_for", ["pane_id": "B", "text": "never Zwei", "timeout": 0.2])
        XCTAssertTrue(reply.isError)
        XCTAssertEqual(reply.content, "timed out waiting for text \"never Zwei\"")
    }

    func testAgentPrivacyRefusesWhatCannotBeConcealed() async {
        store.set(true, for: UserSettings.browserAutomationEvaluate)
        directory.panes = [handle("A"), privateHandle("B", .enabled(privateWords))]
        for (name, args) in [
            ("browser_screenshot", [:]), ("browser_click_at", ["x": 1, "y": 1]),
            ("browser_evaluate", ["expression": "document.title"])
        ] as [(String, [String: Any])] {
            var withPane = args
            withPane["pane_id"] = "B"
            let reply = await call(name, withPane)
            XCTAssertTrue(reply.isError, name)
            XCTAssertEqual(reply.content, BrowserAgentPrivacy.refusal(for: name))
        }
        XCTAssertEqual(directory.revealed, [])
        let open = await call("browser_evaluate", ["pane_id": "A", "expression": "document.title"])
        XCTAssertFalse(open.isError, open.content)
    }

    func testUnreadableWordsCloseThePane() async {
        directory.panes = [handle("A"), privateHandle("B", .unavailable)]
        let reply = await call("browser_snapshot", ["pane_id": "B"])
        XCTAssertTrue(reply.isError)
        XCTAssertEqual(reply.content, BrowserAgentPrivacy.unavailableRefusal)
        XCTAssertEqual(directory.revealed, [])
    }

    func testWordsWhoseStandInsHoldRealWordsCloseThePane() async {
        XCTAssertEqual(BrowserAgentPrivacy.checking(privateWords), .enabled(privateWords))
        for words in ["Alice = Bob; Bob = Alice", "Fred = Ed", "a = b; b = c", "Mikey = Mike"] {
            XCTAssertEqual(BrowserAgentPrivacy.checking(TextSubstitutionFilter(parsing: words)), .conflicting, words)
        }
        directory.panes = [handle("A"), privateHandle("B", .conflicting)]
        let reply = await call("browser_text", ["pane_id": "B"])
        XCTAssertTrue(reply.isError)
        XCTAssertEqual(reply.content, BrowserAgentPrivacy.conflictingRefusal)
    }

    func testListConcealsAPrivatePane() async {
        directory.panes = [handle("A"), privateHandle("B", .enabled(privateWords))]
        var reply = await call("browser_list")
        var rows = try! JSONSerialization.jsonObject(with: Data(reply.content.utf8)) as! [[String: Any]]
        XCTAssertEqual(rows.map { $0["title"] as? String }, ["Alpha", "Gamma"])
        XCTAssertEqual(rows.map { $0["agent_privacy"] as? Bool }, [false, true])
        directory.panes = [handle("A"), BrowserPaneHandle(
            id: "B", project: "beta-portal", tab: "Beta Q3",
            automation: directory.panes[1].automation, agentPrivacy: .enabled(privateWords))]
        reply = await call("browser_list")
        rows = try! JSONSerialization.jsonObject(with: Data(reply.content.utf8)) as! [[String: Any]]
        XCTAssertEqual(rows.last?["project"] as? String, "gamma-portal", "the project name is concealed")
        XCTAssertEqual(rows.last?["tab"] as? String, "Gamma Q3", "the tab name is concealed")
        directory.panes = [handle("A"), privateHandle("B", .unavailable)]
        reply = await call("browser_list")
        rows = try! JSONSerialization.jsonObject(with: Data(reply.content.utf8)) as! [[String: Any]]
        XCTAssertEqual(rows.map { $0["title"] as? String }, ["Alpha", "(concealed)"])
        XCTAssertEqual(rows.map { $0["url"] as? String }.last, "(concealed)")
    }

    func testAgentPrivacyRevealsOnlyWhatGoesIntoThePage() {
        let privacy = BrowserAgentPrivacy.enabled(privateWords)
        let typed = BrowserToolSet.Arguments(tool: "browser_type", values: ["text": "zwei", "url": "https://gamma.test"])
            .revealing(privacy)
        XCTAssertEqual(typed.values["text"] as? String, "Two", "a real word is revealed as the pair gives it")
        XCTAssertEqual(typed.values["url"] as? String, "https://Beta.test")
        let found = BrowserToolSet.Arguments(tool: "browser_find", values: ["text": "Zwei", "scope": "Gamma"])
            .revealing(privacy)
        XCTAssertEqual(found.values["text"] as? String, "Zwei", "a lookup is tried as shown first")
        XCTAssertEqual(found.values["scope"] as? String, "Gamma")
        XCTAssertEqual(try found.candidates("text"), ["Zwei", "Two"])
        let plain = BrowserToolSet.Arguments(tool: "browser_find", values: ["text": "One"]).revealing(privacy)
        XCTAssertEqual(try plain.candidates("text"), ["One"])
    }

    func testAMixedCaseRealWordIsRevealedAsWritten() {
        let privacy = BrowserAgentPrivacy.enabled(TextSubstitutionFilter(pairs: [
            .init(alias: "Acme", real: "OpenAI"), .init(alias: "Bob", real: "Mike Fullerton")
        ]))
        XCTAssertEqual(privacy.revealing("Acme and Bob"), "OpenAI and Mike Fullerton")
        XCTAssertEqual(privacy.revealing("https://github.com/Acme/repo"), "https://github.com/OpenAI/repo")
    }

    func testAnEncodedRealWordIsConcealed() {
        let privacy = BrowserAgentPrivacy.enabled(TextSubstitutionFilter(parsing: "Alex = Mike Fullerton; Zed = Zoë"))
        XCTAssertEqual(privacy.concealing("navigated to https://www.google.com/search?q=Mike+Fullerton"),
                       "navigated to https://www.google.com/search?q=Alex")
        XCTAssertEqual(privacy.concealing("https://x.test/Mike%20Fullerton/zo%c3%ab"), "https://x.test/Alex/zed")
    }

    func testAnAliasInsideAHostIsNotRevealed() {
        let privacy = BrowserAgentPrivacy.enabled(TextSubstitutionFilter(parsing: "Sam = Mike; Robin = Mike"))
        let args = BrowserToolSet.Arguments(tool: "browser_navigate", values: ["url": "https://www.samsung.com/robinhood"])
            .revealing(privacy)
        XCTAssertEqual(args.values["url"] as? String, "https://www.samsung.com/robinhood")
    }

    func testPageWordFilterScriptCarriesThePairsLongestFirst() throws {
        XCTAssertNil(BrowserPageWordFilter.script(for: .identity))
        let script = try XCTUnwrap(BrowserPageWordFilter.script(for: TextSubstitutionFilter(pairs: [
            .init(alias: "Zwei", real: "Two"), .init(alias: "Gamma", real: "Beta Max")
        ])))
        XCTAssertTrue(script.hasPrefix(BrowserPageWordFilter.marker))
        XCTAssertFalse(script.contains("__ADK_PAGE_WORD_PAIRS__"))
        XCTAssertTrue(script.contains(#"[["Beta Max","Gamma"],["Two","Zwei"]]"#), script)
    }

    func testAgentPrivacyIsReadFromThePaneAlone() {
        let layered = LayeredSettingsStore(overrides: InMemorySettingsStorageProvider(), fallback: store)
        XCTAssertFalse(BrowserSettings.isAgentPrivacyOn(in: layered))
        store.set(true, for: UserSettings.browserAgentPrivacy)
        XCTAssertFalse(BrowserSettings.isAgentPrivacyOn(in: layered), "a global value must not turn it on")
        layered.set(true, for: UserSettings.browserAgentPrivacy)
        XCTAssertTrue(BrowserSettings.isAgentPrivacyOn(in: layered))
        XCTAssertFalse(BrowserSettings.isAgentPrivacyOn(in: nil))
    }
}
// swiftlint:enable line_length force_try force_cast
