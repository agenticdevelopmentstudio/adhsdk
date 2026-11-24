import Foundation
import AgenticDeveloperHubSDKCore

/// The twenty-one `browser_*` tools. A `ChatToolSource`, so the same object
/// serves the in-app chats and the MCP server.
public final class BrowserToolSet: ChatToolSource, @unchecked Sendable {

    public static let toolNames = [
        "browser_list", "browser_open", "browser_navigate", "browser_back", "browser_forward",
        "browser_snapshot", "browser_text", "browser_find", "browser_click", "browser_type", "browser_fill",
        "browser_select", "browser_press_key", "browser_hover", "browser_scroll", "browser_wait_for",
        "browser_screenshot", "browser_click_at", "browser_console", "browser_evaluate", "browser_history"
    ]

    /// The tools that only look at a pane. Agent access `readOnly` lets
    /// these through and refuses every other tool; `browser_list` is not about
    /// one pane, so access never refuses it.
    public static let readToolNames: Set<String> = [
        "browser_snapshot", "browser_find", "browser_text", "browser_console",
        "browser_screenshot", "browser_list", "browser_wait_for", "browser_history"
    ]

    static let readOnlyRefusal =
        "This browser pane is read only for the agent (Settings > Privacy > Agent access)."
    static let pausedRefusal = "This browser pane's events are paused, and its settings pause the agent too."

    private let directory: any BrowserPaneDirectory
    private let settings: SettingsStore
    /// The agent lists (`BrowserHiddenItemsStore.shared` in the app).
    private let hiddenItems: @MainActor () -> BrowserHiddenItemsStore?
    /// The one way a tool reads a pane's page (recipe `single-gatekeeper`):
    /// an `AgentPageSource` over the pane's page with the privacy the call
    /// runs under, a spy in tests.
    private let agentPages: @MainActor (BrowserPaneHandle, BrowserAgentPrivacy) -> any AgentPageReader

    @MainActor
    public convenience init(directory: any BrowserPaneDirectory, settings: SettingsStore = UserSettings.shared) {
        // The blocking getter is right here: a tool call drives a page the
        // engine has already read its rules for, so the launch open is done.
        self.init(directory: directory, settings: settings, hiddenItems: { BrowserHiddenItemsStore.shared })
    }

    @MainActor
    init(
        directory: any BrowserPaneDirectory, settings: SettingsStore,
        hiddenItems: @escaping @MainActor () -> BrowserHiddenItemsStore?,
        agentPages: (@MainActor (BrowserPaneHandle, BrowserAgentPrivacy) -> any AgentPageReader)? = nil
    ) {
        self.directory = directory
        self.settings = settings
        self.hiddenItems = hiddenItems
        self.agentPages = agentPages ?? { pane, privacy in
            Self.agentPageSource(for: pane, privacy: privacy, hiddenItems: hiddenItems())
        }
    }

    /// The source a tool reads `pane` through: the pane's own effective Hide
    /// Images (`BrowserPaneHandle.hidesImages`), never the tool set's store,
    /// so the agent receives what the pane's Agent preview shows.
    @MainActor
    static func agentPageSource(for pane: BrowserPaneHandle, privacy: BrowserAgentPrivacy,
                                hiddenItems: BrowserHiddenItemsStore?) -> AgentPageSource {
        AgentPageSource.reading(pane.automation.driver, hiddenItems: hiddenItems, privacy: privacy,
                                hideImages: pane.hidesImages)
    }

    // MARK: ChatToolSource

    public func toolDefinitions() async -> [ToolDefinition] { Self.definitions }

    public func callTool(name: String, argumentsJSON: Data, caller: String?) async -> (content: String, isError: Bool) {
        guard Self.toolNames.contains(name) else { return ("unknown tool \(name)", true) }
        let arguments: [String: Any]
        if argumentsJSON.isEmpty {
            arguments = [:]
        } else if let object = try? JSONSerialization.jsonObject(with: argumentsJSON) as? [String: Any] {
            arguments = object
        } else {
            return ("\(name) arguments are not valid JSON", true)
        }
        let parsed = Arguments(tool: name, values: arguments)
        do {
            // The hop to the main actor is an unstructured task, so cancellation
            // is forwarded to it by hand; otherwise a 60 s wait_for runs on to
            // its end. Over HTTP it arrives from MCPHTTPEndpoint, which turns a
            // caller's notifications/cancelled and FlyingFox's request timeout
            // alike into a cancellation of the SDK's handler task; in a chat it
            // is the stopped turn.
            let work = Task { @MainActor in try await self.dispatch(name, parsed, caller: caller) }
            let reply = try await withTaskCancellationHandler {
                try await work.value
            } onCancel: {
                work.cancel()
            }
            return (reply, false)
        } catch let error as BrowserAutomationError {
            return (error.description, true)
        } catch let error as ToolError {
            return (error.sentence, true)
        } catch {
            return ("\(name) failed: \(error.localizedDescription)", true)
        }
    }

    // MARK: Arguments

    struct ToolError: Error { let sentence: String }

    struct Arguments: @unchecked Sendable {
        let tool: String
        let values: [String: Any]

        func string(_ key: String) throws -> String {
            guard let text = values[key] as? String, !text.isEmpty else {
                throw ToolError(sentence: "\(tool) needs \(key)")
            }
            return text
        }

        /// A required string that may be empty: `browser_fill` with "" clears
        /// the field. A missing, null, numeric or boolean value is still an
        /// error, never a silent "".
        func text(_ key: String) throws -> String {
            guard let text = values[key] as? String else {
                throw ToolError(sentence: "\(tool) needs \(key) as a string")
            }
            return text
        }

        /// An absent key and an empty string both read as "not given".
        func optionalString(_ key: String) -> String? {
            guard let text = values[key] as? String, !text.isEmpty else { return nil }
            return text
        }

        /// A browser engine by its raw value, Safari when not given. A name
        /// that is no engine is an error, never a silent Safari.
        func engine(_ key: String) throws -> BrowserEngineKind {
            guard let name = optionalString(key) else { return .safari }
            guard let engine = BrowserEngineKind(rawValue: name.lowercased()) else {
                let names = BrowserEngineKind.allCases.map(\.rawValue).joined(separator: " or ")
                throw ToolError(sentence: "\(tool) engine must be \(names), not \(name)")
            }
            return engine
        }

        func int(_ key: String) throws -> Int {
            guard let number = optionalInt(key) else { throw ToolError(sentence: "\(tool) needs \(key)") }
            return number
        }

        /// Nil for a missing key, a non-number, a fraction, NaN, infinity or a value outside `Int`.
        func optionalInt(_ key: String) -> Int? {
            guard let number = optionalDouble(key) else { return nil }
            return Int(exactly: number)
        }

        /// Nil for a missing key, a non-number, NaN or infinity.
        func optionalDouble(_ key: String) -> Double? {
            guard let number = values[key] as? Double, number.isFinite else { return nil }
            return number
        }

        func bool(_ key: String) -> Bool { values[key] as? Bool ?? false }

        func url(_ key: String) throws -> URL {
            let raw = try string(key)
            guard let url = URL(string: raw), let scheme = url.scheme?.lowercased(),
                  scheme == "http" || scheme == "https" || raw == "about:blank" else {
                throw ToolError(sentence: "only http and https URLs can be opened")
            }
            return url
        }

        /// The privacy in force when these arguments were revealed, so a
        /// word a model looks something up by can be tried both ways.
        var privacy: BrowserAgentPrivacy = .off

        /// These arguments as the page should receive them. A pane with
        /// Agent Privacy on draws its page with the stand-ins, so what a
        /// model looks a thing up by — a text to find or wait for, an option,
        /// a scope — is left as the model was shown it (`candidates` adds
        /// the real word for text the page script missed). What a model types
        /// or fills goes into the page, and an address goes to the network,
        /// so those are swapped back to the real words first.
        func revealing(_ privacy: BrowserAgentPrivacy) -> Arguments {
            guard privacy.isOn else { return self }
            var revealed = values
            for key in Self.revealedKeys(for: tool) {
                if let text = values[key] as? String { revealed[key] = privacy.revealing(text) }
            }
            return Arguments(tool: tool, values: revealed, privacy: privacy)
        }

        static func revealedKeys(for tool: String) -> [String] {
            switch tool {
            case "browser_type": ["text", "url"]
            case "browser_fill": ["value", "url"]
            // The store and the back/forward list hold the real words, and
            // the reply is concealed again, so a query a model writes with a
            // stand-in finds what the stand-in hides.
            case "browser_history": ["query"]
            default: ["url"]
            }
        }

        /// A lookup word as shown, then as the real word when that differs:
        /// the page shows the stand-in wherever its script reached, and the
        /// real word wherever it did not.
        func candidates(_ key: String) throws -> [String] {
            let shown = try string(key)
            let real = privacy.revealing(shown)
            return real == shown ? [shown] : [shown, real]
        }

        /// The optional `ref` with its `generation`: a ref without a generation is refused,
        /// because Task 2 would otherwise ignore the ref and act on the whole page.
        func optionalRefAndGeneration() throws -> (ref: String?, generation: Int?) {
            guard let ref = optionalString("ref") else { return (nil, nil) }
            return (ref, try int("generation"))
        }
    }

    // MARK: Pane resolution

    @MainActor
    private func resolvePane(_ args: Arguments, caller: String?) throws -> BrowserPaneHandle {
        if let id = args.optionalString("pane_id") {
            guard let pane = directory.browserPane(id: id) else {
                throw ToolError(sentence: "pane \(id) was closed; call browser_list")
            }
            return try guardDrivable(pane)
        }
        if let caller, let pane = directory.browserPane(besidePane: caller) { return try guardDrivable(pane) }
        if let pane = directory.lastUsedBrowserPane() { return try guardDrivable(pane) }
        if let pane = directory.browserPanes().first { return try guardDrivable(pane) }
        throw ToolError(sentence: "no browser pane is open; call browser_open")
    }

    /// Refuses a pane showing a local file before the call is queued, naming
    /// the pane. `requireSwitches(for:paneID:)` checks again once the call is
    /// dequeued, for every tool, and `BrowserAutomation` once more inside each
    /// call that reads the page over time (an action, a wait, a screenshot),
    /// which is what holds when the page changes meanwhile.
    @MainActor
    private func guardDrivable(_ pane: BrowserPaneHandle) throws -> BrowserPaneHandle {
        if !BrowserAutomation.isDrivable(pane.url) {
            throw ToolError(sentence: "pane \(pane.id) shows a local file, which models may not drive")
        }
        return pane
    }

    /// The switches, checked when a call actually runs. A call waits at the
    /// pane's drive gate behind earlier callers, and the user may turn
    /// automation off in the meantime; the check at queue time alone would
    /// let the queued call through.
    @MainActor
    private func requireSwitches(for name: String) throws {
        try requireEnabled()
        if name == "browser_evaluate" { try requireEvaluateEnabled() }
    }

    /// The switches and the pane's own Agent access, checked when a call
    /// actually runs. The handle is looked up again here rather than taken
    /// from before the queue: the user may make the pane read only, pause it,
    /// hide it or close it while the call waits. `browserPanes()` is the
    /// lookup because it is the plain list of what the agent may see.
    ///
    /// A pane that came to show a local file while the call waited is
    /// refused here, whatever the tool — `browser_console` and
    /// `browser_screenshot` have no other check before they read. The one
    /// exception is `browser_open`, whose new pane may already be on its Home
    /// Page, a local file among them, which the call leaves without reading
    /// (`BrowserAutomation.open(_:)`).
    ///
    /// Returns the pane's Agent Privacy as it stands now, so the call is
    /// concealed with the words of the moment it runs.
    @MainActor
    @discardableResult
    private func requireSwitches(for name: String, paneID: String) throws -> BrowserAgentPrivacy {
        try requireSwitches(for: name)
        guard let pane = directory.browserPanes().first(where: { $0.id == paneID }) else {
            throw ToolError(sentence: "pane \(paneID) was closed; call browser_list")
        }
        try requireAccess(for: name, on: pane)
        if name != "browser_open" { try pane.automation.ensureDrivable() }
        return pane.agentPrivacy
    }

    /// The pane's Agent access and pause state against the tool: a pane
    /// paused for the agent refuses every tool, a read-only one every tool
    /// that is not a read. A hidden pane reaches here only straight from
    /// `openBrowserPane`, the one path that does not go through `visible`,
    /// and is answered as a pane that does not exist, so the refusal says
    /// nothing a hidden pane would not.
    @MainActor
    private func requireAccess(for name: String, on pane: BrowserPaneHandle) throws {
        if pane.access == .hidden { throw ToolError(sentence: "pane \(pane.id) was closed; call browser_list") }
        if pane.isPausedForAgent { throw ToolError(sentence: Self.pausedRefusal) }
        if pane.access == .readOnly, !Self.readToolNames.contains(name) {
            throw ToolError(sentence: Self.readOnlyRefusal)
        }
        if let refusal = pane.agentPrivacy.closedRefusal() { throw ToolError(sentence: refusal) }
        if pane.agentPrivacy.isOn, BrowserAgentPrivacy.refusedToolNames.contains(name) {
            throw ToolError(sentence: BrowserAgentPrivacy.refusal(for: name))
        }
        // Console output is the page's words in any shape (recipe
        // `console-refused-under-privacy`).
        if pane.agentPrivacy.isOn, name == "browser_console" {
            throw ToolError(sentence: BrowserAgentPrivacy.consoleRefusal)
        }
    }

    /// Why `tool`, one of `BrowserAgentPrivacy.refusedToolNames` (a
    /// screenshot, a click at a point, an evaluate: tools that see the raw
    /// page past the agent's view), is refused on `pane`, or nil when it is
    /// not (recipe `raw-page-tools-refused-when-filtered`): Agent Privacy is
    /// on, or the site has enabled agent-list entries. An agent list that
    /// cannot be read refuses too, as the agent page then fails closed.
    @MainActor
    func rawPageRefusal(pane: BrowserPaneHandle, tool: String) async -> String? {
        let now = directory.browserPanes().first { $0.id == pane.id } ?? pane
        if now.agentPrivacy.isOn { return now.agentPrivacy.closedRefusal() ?? BrowserAgentPrivacy.refusal(for: tool) }
        guard let store = hiddenItems() else {
            return AgentPage.unavailablePrefix + AgentPageSourceError.agentListUnavailable.description
        }
        let url = now.automation.driver.url
        do {
            let selectors = try await store.perform { try $0.enabledSelectors(list: .agent, for: url) }
            return selectors.isEmpty ? nil : BrowserAgentPrivacy.agentListRefusal
        } catch {
            return AgentPage.unavailablePrefix + error.localizedDescription
        }
    }

    /// One call's way to the agent's page: every read of the page goes
    /// through `reader`, every string the page wrote through `builder`.
    @MainActor
    struct AgentView {
        let reader: any AgentPageReader
        let builder: AgentPageBuilder

        /// A walk whose local-file failure is thrown as the sentence the
        /// tools say it with; every other failure is the unavailable page.
        func read(_ options: BrowserSnapshotOptions, keepingRefs: Bool) async throws -> AgentPageReading {
            let reading = await reader.read(options: options, keepingRefs: keepingRefs)
            try Task.checkCancellation()
            if case .localFile? = reading.failure { throw BrowserAutomationError.localFile }
            return reading
        }
    }

    @MainActor
    private func agentView(_ pane: BrowserPaneHandle, _ privacy: BrowserAgentPrivacy) -> AgentView {
        AgentView(reader: agentPages(pane, privacy),
                  builder: AgentPageBuilder(privacy: privacy, hideImages: pane.hidesImages))
    }

    /// An action's reply as the agent may see it: its title and dialog
    /// message through the string path, and the focused element as the
    /// agent page shows it — omitted when its ref is not on that page
    /// (recipe `titles-dialogs-focus-through-string-path`).
    @MainActor
    private func agentReply(_ delta: BrowserActionDelta, _ agent: AgentView) async throws -> String {
        var focused: String?
        // A focus read on a page the action itself moved to a local file
        // throws `localFile`, and the reply is that sentence, not the delta:
        // deliberate, since nothing of a local file may reach the agent.
        if let ref = delta.focusedRef {
            var options = BrowserSnapshotOptions()
            options.scope = ref
            options.depth = 4
            let page = try await agent.read(options, keepingRefs: true).page
            if page.unavailableReason == nil, page.node(ref: ref) != nil {
                focused = page.snapshotTree(AgentPageSource.renderingOptions(options))
            }
        }
        return delta.agentView(conceal: agent.builder.conceal, focused: focused).rendered()
    }

    /// The elements of `page` whose name or own text contains `text`, case
    /// and whitespace aside, in page order: the agent page's refs, as
    /// `browser_snapshot` prints them (recipe `find-uses-agent-page`).
    static func find(_ text: String, in page: AgentPage) -> [BrowserFindMatch] {
        guard let root = page.root else { return [] }
        let needle = AgentPageText.collapse(text).lowercased()
        guard !needle.isEmpty else { return [] }
        let tree = AgentSnapshotMapper(interactiveOnly: false, title: page.title).root(root, depth: nil)
        var matches: [BrowserFindMatch] = []
        collect(tree, needle, into: &matches)
        return matches
    }

    private static func collect(_ node: BrowserSnapshotNode, _ needle: String, into matches: inout [BrowserFindMatch]) {
        if let ref = node.ref {
            // Its own name and its own text lines only: a container must not
            // match on its descendants' text, as the legacy find did not.
            let own = [node.name, node.text].compactMap { $0 }
                + node.children.filter { $0.role == "text" }.compactMap(\.text)
            if own.joined(separator: " ").lowercased().contains(needle) {
                matches.append(BrowserFindMatch(ref: ref, role: node.role, name: node.name ?? ""))
            }
        }
        for child in node.children { collect(child, needle, into: &matches) }
    }

    /// The whole agent page's text, every block, for `browser_wait_for`
    /// (recipe `wait-for-uses-agent-text`); nil while the page is unavailable.
    static func wholeText(_ page: AgentPage) -> String? {
        guard page.unavailableReason == nil else { return nil }
        guard let root = page.root else { return "" }
        var renderer = AgentTextRenderer()
        renderer.visit(root)
        return renderer.finish()
    }

    /// Runs `body` with `args` revealed when the pane's Agent Privacy is on,
    /// and conceals what it returns or throws. An error's sentence can quote
    /// the page (a ref's name, a text not found), so it is concealed as
    /// carefully as a reply. A cancellation passes through as it is: it says
    /// nothing about the page, and the caller must see it as one.
    ///
    /// What comes back is concealed with the words of every site the call
    /// touched: the pane's Agent Privacy as it stood when the call started
    /// and as it stands when it returns, together
    /// (`BrowserAgentPrivacy.combined(with:)`). A call can run for a minute
    /// (`browser_wait_for`), and meanwhile the user may turn the setting on or
    /// change the words, or the page may move to a site the start words do
    /// not cover; a real word revealed with the start words then comes back
    /// in the reply (an address navigated to, a waited-for fragment repeated
    /// in a timeout) and is still concealed. If the setting was turned off
    /// meanwhile, the words the call started with still apply.
    @MainActor
    private func concealed(
        _ name: String, _ args: Arguments, _ privacy: BrowserAgentPrivacy, paneID: String,
        _ body: (Arguments) async throws -> String
    ) async throws -> String {
        let outcome: Result<String, Error>
        do {
            outcome = .success(try await body(privacy.isOn ? args.revealing(privacy) : args))
        } catch {
            outcome = .failure(error)
        }
        let now = directory.browserPanes().first { $0.id == paneID }?.agentPrivacy ?? privacy
        let shield = privacy.combined(with: now)
        guard shield.isOn else { return try outcome.get() }
        switch outcome {
        case .success(let reply):
            return shield.concealing(reply)
        case .failure(let error as CancellationError):
            throw error
        case .failure(let error as BrowserAutomationError):
            throw ToolError(sentence: shield.concealing(error.description))
        case .failure(let error as ToolError):
            throw ToolError(sentence: shield.concealing(error.sentence))
        case .failure(let error):
            throw ToolError(sentence: shield.concealing("\(name) failed: \(error.localizedDescription)"))
        }
    }

    @MainActor
    private func requireEnabled() throws {
        guard settings.get(UserSettings.browserAutomationEnabled) else {
            throw ToolError(sentence: "browser automation is turned off in Settings")
        }
    }

    @MainActor
    private func requireEvaluateEnabled() throws {
        guard settings.get(UserSettings.browserAutomationEvaluate) else {
            throw ToolError(sentence: "browser_evaluate is turned off in Settings")
        }
    }

    // MARK: Dispatch

    @MainActor
    private func dispatch(_ name: String, _ args: Arguments, caller: String?) async throws -> String {
        if name == "browser_list" { return listPanes(caller: caller) }
        try requireSwitches(for: name)
        if name == "browser_open" {
            let url = args.optionalString("url") == nil ? openWithoutURLPage() : try args.url("url")
            let engine = try args.engine("engine")
            let pane = try directory.openBrowserPane(besidePane: caller, engine: engine)
            // A pane whose settings refuse the agent (a hidden, read-only or
            // paused default) is closed again at once and the open refused
            // with the same sentence as any other refused open, so neither
            // the pane nor the reason is left behind or named.
            do {
                try requireAccess(for: name, on: pane)
            } catch {
                directory.closeBrowserPane(id: pane.id)
                throw BrowserAutomationError.openRefused
            }
            directory.revealBrowserPane(id: pane.id)
            return try await pane.automation.drive {
                // A new pane starts with Agent Privacy off, but the check is
                // the same as every other call's, so it can never be skipped.
                let privacy = try self.requireSwitches(for: name, paneID: pane.id)
                let agent = self.agentView(pane, privacy)
                return try await self.concealed(name, args, privacy, paneID: pane.id) { _ in
                    do {
                        let delta = try await pane.automation.open(url)
                        let reply = try await self.agentReply(delta, agent)
                        return "opened pane \(pane.id)\n" + reply
                    } catch BrowserAutomationError.localFile {
                        // A pane that ends on a local file is not left behind
                        // for the model to retry into, one more each time.
                        self.directory.closeBrowserPane(id: pane.id)
                        throw BrowserAutomationError.localFile
                    }
                }
            }
        }
        let pane = try resolvePane(args, caller: caller)
        if name == "browser_history" { return try await history(args, pane) }
        // Refused at once when the pane already refuses, rather than after
        // waiting behind other callers; checked again once dequeued. The
        // pane's project is put on screen only once access has passed, so a
        // refused call changes nothing the user can see.
        try requireAccess(for: name, on: pane)
        let raw = BrowserAgentPrivacy.refusedToolNames.contains(name)
        if raw, let refusal = await rawPageRefusal(pane: pane, tool: name) { throw ToolError(sentence: refusal) }
        directory.revealBrowserPane(id: pane.id)
        let automation = pane.automation
        return try await automation.drive {
            let privacy = try self.requireSwitches(for: name, paneID: pane.id)
            // Checked again once dequeued: the site or its agent list may
            // have changed while the call waited.
            if raw, let refusal = await self.rawPageRefusal(pane: pane, tool: name) {
                throw ToolError(sentence: refusal)
            }
            let agent = self.agentView(pane, privacy)
            return try await self.concealed(name, args, privacy, paneID: pane.id) { args in
                if let delta = try await self.dispatchNavigation(name, args, automation) {
                    return try await self.agentReply(delta, agent)
                }
                if let reply = try await self.dispatchReading(name, args, automation, agent,
                                                              mayScroll: pane.access != .readOnly) { return reply }
                if let delta = try await self.dispatchActions(name, args, automation) {
                    return try await self.agentReply(delta, agent)
                }
                throw ToolError(sentence: "unknown tool \(name)")
            }
        }
    }

    /// `browser_history`: the visits the pane's Agent can see history allows.
    /// The pane's access is checked as for every tool, closed privacy
    /// included, before the setting is looked at. It does not wait at the
    /// pane's drive gate or put the pane's project on screen: it reads
    /// neither the page nor anything the page can change, only the tab's
    /// back/forward list and the store, so there is no page to drive and
    /// nothing for the user to watch.
    @MainActor
    private func history(_ args: Arguments, _ pane: BrowserPaneHandle) async throws -> String {
        let name = "browser_history"
        try requireAccess(for: name, on: pane)
        if let value = args.values["query"], !(value is NSNull), !(value is String) {
            throw ToolError(sentence: "\(name) needs query as a string")
        }
        let limit: Int
        if let value = args.values["limit"], !(value is NSNull) {
            guard let number = args.optionalInt("limit") else {
                throw ToolError(sentence: "\(name) needs limit as an integer")
            }
            limit = number
        } else {
            limit = BrowserHistoryTool.defaultLimit
        }
        let privacy = try requireSwitches(for: name, paneID: pane.id)
        // The handle is looked up again so the setting is the one in force
        // now (`effective-access-per-pane`); `requireSwitches` has just
        // found it.
        let now = directory.browserPanes().first { $0.id == pane.id } ?? pane
        // Read here, on the main actor, and only when the setting allows it.
        let backForward = now.historyAccess == .currentTab ? now.backForward : []
        // History lists other sites' pages, so each line is concealed with
        // every enabled word whatever its sites, not only the page in
        // front's (`historyPrivacy`); a closed side refuses.
        let linePrivacy = now.historyPrivacy.combined(with: privacy)
        return try await concealed(name, args, privacy, paneID: pane.id) { args in
            try await BrowserHistoryTool.run(
                access: now.historyAccess, query: args.optionalString("query"), limit: limit,
                store: now.historyStore, backForward: backForward, privacy: linePrivacy)
        }
    }

    /// What `browser_open` loads when no URL is given: the Home Page setting
    /// when it names an http or https page, else a blank page. A home page of
    /// any other scheme is not one a model may be handed (`file:` panes are
    /// refused everywhere else), so it falls to blank too.
    @MainActor
    private func openWithoutURLPage() -> URL {
        if let home = BrowserSettings.homePage(in: settings),
           let scheme = home.scheme?.lowercased(), scheme == "http" || scheme == "https" {
            return home
        }
        return WebBrowserPaneViewController.blankPage
    }

    @MainActor
    private func dispatchNavigation(
        _ name: String, _ args: Arguments, _ automation: BrowserAutomation
    ) async throws -> BrowserActionDelta? {
        switch name {
        case "browser_navigate": return try await automation.navigate(to: try args.url("url"))
        case "browser_back": return try await automation.goBack()
        case "browser_forward": return try await automation.goForward()
        default: return nil
        }
    }

    @MainActor
    /// `mayScroll` is false for a Read only pane: reading must not move the
    /// page, so an element screenshot captures the element where it is.
    private func dispatchReading(
        _ name: String, _ args: Arguments, _ automation: BrowserAutomation, _ agent: AgentView, mayScroll: Bool
    ) async throws -> String? {
        switch name {
        case "browser_snapshot":
            var options = BrowserSnapshotOptions()
            options.interactiveOnly = args.bool("interactive_only")
            options.depth = args.optionalInt("depth")
            options.scope = args.optionalString("scope")
            options.includeURLs = args.bool("include_urls")
            options.delta = args.bool("delta")
            let reading = try await agent.read(options, keepingRefs: false)
            let page = reading.page
            if let reason = page.unavailableReason { return reason }
            let tree = page.snapshotTree(AgentPageSource.renderingOptions(options))
            let text = automation.agentSnapshotText(tree, delta: options.delta)
            let url = page.url?.absoluteString ?? automation.currentURL
            return "url: \(url)\ntitle: \(page.title)\ngeneration: \(reading.generation ?? 0)\n\n\(text)"
        case "browser_text":
            var options = BrowserSnapshotOptions()
            options.scope = args.optionalString("scope")
            return try await agent.read(options, keepingRefs: true).page.text()
        case "browser_find":
            let candidates = try args.candidates("text")
            let page = try await agent.read(BrowserSnapshotOptions(), keepingRefs: true).page
            if let reason = page.unavailableReason { return reason }
            var matches: [BrowserFindMatch] = []
            for text in candidates where matches.isEmpty {
                matches = Self.find(text, in: page)
            }
            if matches.isEmpty { return "no element matches" }
            return matches.map { "\($0.ref) \($0.role) \"\($0.name)\"" }.joined(separator: "\n")
        case "browser_wait_for":
            let condition = try waitCondition(args)
            let result = try await automation.wait(for: condition, timeout: args.optionalDouble("timeout")) {
                // A failed read (cancelled, or a local file) is "not yet":
                // the wait's next pass surfaces either from its own checks.
                guard let page = try? await agent.read(BrowserSnapshotOptions(), keepingRefs: true).page else {
                    return nil
                }
                return Self.wholeText(page)
            }
            return "satisfied\nurl: \(result.url)\ntitle: \(agent.builder.conceal(result.title))"
        case "browser_screenshot":
            let target = try args.optionalRefAndGeneration()
            let png = try await automation.screenshot(ref: target.ref, generation: target.generation,
                                                      scrolls: mayScroll)
            return "data:image/png;base64," + png.base64EncodedString()
        case "browser_console":
            guard automation.isConsoleCaptureOn else { return "Console capture is off for this pane." }
            let messages = automation.console.messages(level: args.optionalString("level"))
            if messages.isEmpty { return "no console messages" }
            return messages.map { "[\($0.level)] \($0.text)" }.joined(separator: "\n")
        case "browser_evaluate":
            return try await automation.evaluate(try args.string("expression"))
        default:
            return nil
        }
    }

    @MainActor
    private func dispatchActions(
        _ name: String, _ args: Arguments, _ automation: BrowserAutomation
    ) async throws -> BrowserActionDelta? {
        switch name {
        case "browser_click":
            return try await automation.click(
                ref: try args.string("ref"), generation: try args.int("generation"), native: args.bool("native")
            )
        case "browser_type":
            return try await automation.type(
                ref: try args.string("ref"), generation: try args.int("generation"),
                text: try args.string("text"), submit: args.bool("submit")
            )
        case "browser_fill":
            return try await automation.fill(
                ref: try args.string("ref"), generation: try args.int("generation"),
                value: try args.text("value")
            )
        case "browser_select":
            let ref = try args.string("ref"), generation = try args.int("generation")
            let values = try args.candidates("value")
            for value in values.dropLast() {
                // A miss tries the next value; a cancellation does not, since
                // the attempt may already have fired input and change, and a
                // cancelled call must not act on the page again.
                do {
                    return try await automation.select(ref: ref, generation: generation, value: value)
                } catch let error as CancellationError {
                    throw error
                } catch {
                    try Task.checkCancellation()
                }
            }
            return try await automation.select(ref: ref, generation: generation, value: values.last ?? "")
        case "browser_press_key":
            return try await automation.pressKey(try args.string("key"))
        case "browser_hover":
            return try await automation.hover(
                ref: try args.string("ref"), generation: try args.int("generation")
            )
        case "browser_scroll":
            let target = try args.optionalRefAndGeneration()
            return try await automation.scroll(
                ref: target.ref, generation: target.generation,
                direction: args.optionalString("direction"), amount: args.optionalInt("amount")
            )
        case "browser_click_at":
            guard let xPoint = args.optionalDouble("x"), let yPoint = args.optionalDouble("y") else {
                throw ToolError(sentence: "browser_click_at needs x and y")
            }
            return try await automation.clickAt(x: xPoint, y: yPoint)
        default:
            return nil
        }
    }

    private func waitCondition(_ args: Arguments) throws -> BrowserWaitCondition {
        if args.optionalString("text") != nil {
            let texts = try args.candidates("text")
            return texts.count == 1 ? .text(texts[0]) : .anyText(texts)
        }
        if let ref = args.optionalString("ref") { return .ref(ref, generation: try args.int("generation")) }
        if let url = args.optionalString("url") { return .url(url) }
        if args.bool("load") { return .load }
        if args.bool("idle") { return .idle }
        throw ToolError(sentence: "browser_wait_for needs one of text, ref, url, load, idle")
    }

    @MainActor
    private func listPanes(caller: String?) -> String {
        let panes = directory.browserPanes()
        if panes.isEmpty { return "no browser pane is open; call browser_open" }
        let defaultID = (try? resolvePane(Arguments(tool: "browser_list", values: [:]), caller: caller))?.id
        // A private pane's row is concealed whole, as a private terminal
        // conceals its project and branch: the title and address are the
        // page's words, and the project and tab names are the user's. One
        // whose words cannot be used shows none of them.
        // A pane on a local file names neither the file nor its title: the
        // user's disk is not the model's to read through a pane, a listing
        // included.
        let rows: [[String: Any]] = panes.map { pane in
            let privacy = pane.agentPrivacy
            let drivable = BrowserAutomation.isDrivable(pane.url)
            // The title is the page's words: through the agent page's string
            // path (recipe `titles-dialogs-focus-through-string-path`), which
            // writes nothing of a closed pane's; the list says so in words.
            let concealed = AgentPageBuilder(privacy: privacy, hideImages: false).conceal(pane.title)
            let title = concealed.isEmpty && privacy.closedRefusal() != nil ? "(concealed)" : concealed
            return [
                "id": pane.id, "title": drivable ? title : Self.localFileName,
                "url": drivable ? privacy.concealing(pane.url) : Self.localFileName,
                "project": privacy.concealing(pane.project),
                "tab": privacy.concealing(pane.tab), "engine": pane.engine.rawValue, "is_default": pane.id == defaultID,
                "access": Self.accessName(pane.access), "agent_privacy": pane.agentPrivacy.isOn
            ]
        }
        let data = (try? JSONSerialization.data(withJSONObject: rows, options: [.sortedKeys])) ?? Data()
        return String(bytes: data, encoding: .utf8) ?? ""
    }

    /// What `browser_list` shows for the title and address of a pane on a
    /// local file.
    static let localFileName = "(local file)"

    /// How `browser_list` names a pane's Agent access.
    static func accessName(_ access: BrowserAgentAccess) -> String {
        switch access {
        case .full: "full"
        case .readOnly: "read only"
        case .hidden: "hidden"
        }
    }

    // MARK: Definitions

    // swiftlint:disable line_length

    private static var paneID: [String: Any] { ToolJSONSchema.string("Browser pane id from browser_list; omit for the default pane") }
    private static var refGen: [String: [String: Any]] { [
        "pane_id": paneID,
        "ref": ToolJSONSchema.string("Element ref from the last browser_snapshot, e.g. e12"),
        "generation": ToolJSONSchema.integer("The generation the ref came from")
    ] }

    private static func tool(_ name: String, _ description: String, _ properties: [String: [String: Any]], required: [String] = []) -> ToolDefinition {
        ToolDefinition(name: name, description: description, parametersJSONSchema: ToolJSONSchema.object(properties: properties, required: required))
    }

    static let definitions: [ToolDefinition] = [
        tool("browser_list", "List the open Browser panes: id, title, url, project, tab, engine (safari or chrome), access (full, or read only: snapshot, find, text, console, screenshot, wait and history only), and which one is the default for this caller.", [:]),
        tool("browser_open", "Open a new Browser pane beside the caller and load a URL (http or https), or the home page (else a blank page) when no URL is given. Every other tool drives a Safari pane and a Chrome pane the same way.", [
            "url": ToolJSONSchema.string("The page to load; optional"),
            "engine": ToolJSONSchema.string("safari (WebKit) or chrome (Chromium); optional, safari by default")
        ]),
        tool("browser_navigate", "Load a URL in a Browser pane.", ["url": ToolJSONSchema.string("The page to load"), "pane_id": paneID], required: ["url"]),
        tool("browser_back", "Go back one page.", ["pane_id": paneID]),
        tool("browser_forward", "Go forward one page.", ["pane_id": paneID]),
        tool("browser_snapshot", "The page as an accessibility tree with refs (e1, e2, …) for every interactive element. Take one before acting; refs expire on the next snapshot.", [
            "pane_id": paneID,
            "interactive_only": ToolJSONSchema.boolean("Only elements that can be acted on"),
            "depth": ToolJSONSchema.integer("Maximum tree depth"),
            "scope": ToolJSONSchema.string("A ref from the last snapshot to snapshot under; a ref that names nothing gives the whole page"),
            "include_urls": ToolJSONSchema.boolean("Add [url=…] to links"),
            "delta": ToolJSONSchema.boolean("Only what changed since the last snapshot, in page order: lines added (with refs), lines removed, and lines renumbered (same line, new ref)")
        ]),
        tool("browser_text", "The visible text of the page (its main region, else the whole body).", ["pane_id": paneID, "scope": ToolJSONSchema.string("A ref from the last snapshot; a ref that names nothing gives the whole page")]),
        tool("browser_find", "Find elements from the last snapshot (taking one if there is none) whose name or text contains the given text.", ["pane_id": paneID, "text": ToolJSONSchema.string("Text to look for, case-insensitive")], required: ["text"]),
        tool("browser_click", "Click an element by ref.", refGen.merging(["native": ToolJSONSchema.boolean("Send a real mouse click instead of a DOM click")]) { $1 }, required: ["ref", "generation"]),
        tool("browser_type", "Type text into a textbox, textarea or contenteditable key by key, appending to what is there. A select takes browser_select; a checkbox, radio or button takes browser_click.", refGen.merging(["text": ToolJSONSchema.string("Text to type"), "submit": ToolJSONSchema.boolean("Press Enter afterwards")]) { $1 }, required: ["ref", "generation", "text"]),
        tool("browser_fill", "Replace a textbox, textarea or contenteditable's value, firing input and change. A select takes browser_select; a checkbox, radio or button takes browser_click.", refGen.merging(["value": ToolJSONSchema.string("The new value")]) { $1 }, required: ["ref", "generation", "value"]),
        tool("browser_select", "Choose an option of a select by value or label.", refGen.merging(["value": ToolJSONSchema.string("Option value or label")]) { $1 }, required: ["ref", "generation", "value"]),
        tool("browser_press_key", "Press a key on the focused element: Enter, Escape, Tab, ArrowDown, a, with Meta+/Shift+/Alt+/Control+ prefixes.", ["pane_id": paneID, "key": ToolJSONSchema.string("The key, e.g. Enter or Meta+a")], required: ["key"]),
        tool("browser_hover", "Hover an element by ref.", refGen, required: ["ref", "generation"]),
        tool("browser_scroll", "Scroll an element into view, or scroll the page.", refGen.merging(["direction": ToolJSONSchema.string("up, down, left or right"), "amount": ToolJSONSchema.integer("Pixels")]) { $1 }),
        tool("browser_wait_for", "Wait until text appears, a ref is visible, the URL contains a string, the page loads, or the DOM is idle. Give exactly one of text, ref, url, load, idle.", [
            "pane_id": paneID, "text": ToolJSONSchema.string("Text that must appear"), "ref": ToolJSONSchema.string("Ref that must be visible"),
            "generation": ToolJSONSchema.integer("Generation of the ref"), "url": ToolJSONSchema.string("Substring the URL must contain"),
            "load": ToolJSONSchema.boolean("Wait for the page to finish loading"), "idle": ToolJSONSchema.boolean("Wait for the DOM to stop changing"),
            "timeout": ToolJSONSchema.number("Seconds, default 10, at most 60")
        ]),
        tool("browser_screenshot", "A PNG of the viewport, or of one element by ref. Its pixels are the coordinates browser_click_at takes. Refused while Agent Privacy is on or when the site has items hidden from the agent.", refGen),
        tool("browser_click_at", "A real mouse click at a point of the last browser_screenshot, in that image's pixels. Take a screenshot first; browser_click by ref is the usual way. Refused while Agent Privacy is on or when the site has items hidden from the agent.", ["pane_id": paneID, "x": ToolJSONSchema.number("Pixels from the left edge of the last screenshot"), "y": ToolJSONSchema.number("Pixels from the top edge of the last screenshot")], required: ["x", "y"]),
        tool("browser_console", "The page's last console messages and errors. Refused while Agent Privacy is on.", ["pane_id": paneID, "level": ToolJSONSchema.string("log, info, warn, error or debug")]),
        tool("browser_evaluate", "Evaluate a JavaScript expression in the page and return its JSON. Off unless enabled in Settings. Refused while Agent Privacy is on or when the site has items hidden from the agent.", ["pane_id": paneID, "expression": ToolJSONSchema.string("The expression")], required: ["expression"]),
        tool("browser_history", "Recent visits the user allows the agent to see: all history, this tab's back/forward list, or none (refused).", [
            "pane_id": paneID,
            "query": ToolJSONSchema.string("Keep only visits whose title or address contains this, case-insensitive; optional"),
            "limit": ToolJSONSchema.integer("At most this many visits, newest first; default 50, at most 200")
        ])
    ]
    // swiftlint:enable line_length
}
