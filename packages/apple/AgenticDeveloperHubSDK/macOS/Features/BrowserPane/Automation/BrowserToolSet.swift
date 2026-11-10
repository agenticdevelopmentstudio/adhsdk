import Foundation
import AgenticDeveloperHubSDKCore

/// The twenty `browser_*` tools. A `ChatToolSource`, so the same object
/// serves the in-app chats and the MCP server.
public final class BrowserToolSet: ChatToolSource, @unchecked Sendable {

    public static let toolNames = [
        "browser_list", "browser_open", "browser_navigate", "browser_back", "browser_forward",
        "browser_snapshot", "browser_text", "browser_find", "browser_click", "browser_type", "browser_fill",
        "browser_select", "browser_press_key", "browser_hover", "browser_scroll", "browser_wait_for",
        "browser_screenshot", "browser_click_at", "browser_console", "browser_evaluate"
    ]

    /// The tools that only look at a pane. Agent access `readOnly` lets
    /// these through and refuses every other tool; `browser_list` is not about
    /// one pane, so access never refuses it.
    public static let readToolNames: Set<String> = [
        "browser_snapshot", "browser_find", "browser_text", "browser_console",
        "browser_screenshot", "browser_list", "browser_wait_for"
    ]

    static let readOnlyRefusal =
        "This browser pane is read only for the agent (Settings > Session Privacy > Agent access)."
    static let pausedRefusal = "This browser pane's events are paused, and its settings pause the agent too."

    private let directory: any BrowserPaneDirectory
    private let settings: SettingsStore

    @MainActor
    public init(directory: any BrowserPaneDirectory, settings: SettingsStore = UserSettings.shared) {
        self.directory = directory
        self.settings = settings
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

        /// These arguments as the page should receive them: what a model
        /// types, fills, selects, finds, waits for or navigates to may carry
        /// the stand-ins it was shown, so a pane with Agent Privacy on swaps
        /// them back to the real words first.
        func revealing(_ privacy: BrowserAgentPrivacy) -> Arguments {
            guard privacy.isOn else { return self }
            var revealed = values
            for key in Self.revealedKeys {
                if let text = values[key] as? String { revealed[key] = privacy.revealing(text) }
            }
            return Arguments(tool: tool, values: revealed)
        }

        static let revealedKeys = ["text", "value", "url", "scope"]

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
    /// the pane. `BrowserAutomation` enforces the same rule again at the moment
    /// each call runs, which is what holds when the page changes meanwhile.
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
        if pane.agentPrivacy == .unavailable { throw ToolError(sentence: BrowserAgentPrivacy.unavailableRefusal) }
        if pane.agentPrivacy.isOn, BrowserAgentPrivacy.refusedToolNames.contains(name) {
            throw ToolError(sentence: BrowserAgentPrivacy.refusal(for: name))
        }
    }

    /// Runs `body` with `args` revealed, and conceals what it returns or
    /// throws, when the pane's Agent Privacy is on. An error's sentence can
    /// quote the page (a ref's name, a text not found), so it is concealed as
    /// carefully as a reply. A cancellation passes through as it is: it says
    /// nothing about the page, and the caller must see it as one.
    @MainActor
    private func concealed(
        _ name: String, _ args: Arguments, _ privacy: BrowserAgentPrivacy,
        _ body: (Arguments) async throws -> String
    ) async throws -> String {
        guard privacy.isOn else { return try await body(args) }
        do {
            return privacy.concealing(try await body(args.revealing(privacy)))
        } catch let error as CancellationError {
            throw error
        } catch let error as BrowserAutomationError {
            throw ToolError(sentence: privacy.concealing(error.description))
        } catch let error as ToolError {
            throw ToolError(sentence: privacy.concealing(error.sentence))
        } catch {
            throw ToolError(sentence: privacy.concealing("\(name) failed: \(error.localizedDescription)"))
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
                return try await self.concealed(name, args, privacy) { _ in
                    let delta = try await pane.automation.navigate(to: url)
                    return "opened pane \(pane.id)\n" + delta.rendered()
                }
            }
        }
        let pane = try resolvePane(args, caller: caller)
        // Refused at once when the pane already refuses, rather than after
        // waiting behind other callers; checked again once dequeued. The
        // pane's project is put on screen only once access has passed, so a
        // refused call changes nothing the user can see.
        try requireAccess(for: name, on: pane)
        directory.revealBrowserPane(id: pane.id)
        let automation = pane.automation
        return try await automation.drive {
            let privacy = try self.requireSwitches(for: name, paneID: pane.id)
            return try await self.concealed(name, args, privacy) { args in
                if let reply = try await self.dispatchNavigation(name, args, automation) { return reply }
                if let reply = try await self.dispatchReading(name, args, automation,
                                                              mayScroll: pane.access != .readOnly) { return reply }
                if let reply = try await self.dispatchActions(name, args, automation) { return reply }
                throw ToolError(sentence: "unknown tool \(name)")
            }
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
    ) async throws -> String? {
        switch name {
        case "browser_navigate": return try await automation.navigate(to: try args.url("url")).rendered()
        case "browser_back": return try await automation.goBack().rendered()
        case "browser_forward": return try await automation.goForward().rendered()
        default: return nil
        }
    }

    @MainActor
    /// `mayScroll` is false for a Read only pane: reading must not move the
    /// page, so an element screenshot captures the element where it is.
    private func dispatchReading(
        _ name: String, _ args: Arguments, _ automation: BrowserAutomation, mayScroll: Bool
    ) async throws -> String? {
        switch name {
        case "browser_snapshot":
            var options = BrowserSnapshotOptions()
            options.interactiveOnly = args.bool("interactive_only")
            options.depth = args.optionalInt("depth")
            options.scope = args.optionalString("scope")
            options.includeURLs = args.bool("include_urls")
            options.delta = args.bool("delta")
            let snap = try await automation.snapshot(options)
            return "url: \(snap.url)\ntitle: \(snap.title)\ngeneration: \(snap.generation)\n\n\(snap.text)"
        case "browser_text":
            return try await automation.text(scope: args.optionalString("scope"))
        case "browser_find":
            let matches = try await automation.find(try args.string("text"))
            if matches.isEmpty { return "no element matches" }
            return matches.map { "\($0.ref) \($0.role) \"\($0.name)\"" }.joined(separator: "\n")
        case "browser_wait_for":
            let condition = try waitCondition(args)
            let result = try await automation.wait(for: condition, timeout: args.optionalDouble("timeout"))
            return "satisfied\nurl: \(result.url)\ntitle: \(result.title)"
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
    ) async throws -> String? {
        switch name {
        case "browser_click":
            return try await automation.click(
                ref: try args.string("ref"), generation: try args.int("generation"), native: args.bool("native")
            ).rendered()
        case "browser_type":
            return try await automation.type(
                ref: try args.string("ref"), generation: try args.int("generation"),
                text: try args.string("text"), submit: args.bool("submit")
            ).rendered()
        case "browser_fill":
            return try await automation.fill(
                ref: try args.string("ref"), generation: try args.int("generation"),
                value: try args.text("value")
            ).rendered()
        case "browser_select":
            return try await automation.select(
                ref: try args.string("ref"), generation: try args.int("generation"), value: try args.string("value")
            ).rendered()
        case "browser_press_key":
            return try await automation.pressKey(try args.string("key")).rendered()
        case "browser_hover":
            return try await automation.hover(
                ref: try args.string("ref"), generation: try args.int("generation")
            ).rendered()
        case "browser_scroll":
            let target = try args.optionalRefAndGeneration()
            return try await automation.scroll(
                ref: target.ref, generation: target.generation,
                direction: args.optionalString("direction"), amount: args.optionalInt("amount")
            ).rendered()
        case "browser_click_at":
            guard let xPoint = args.optionalDouble("x"), let yPoint = args.optionalDouble("y") else {
                throw ToolError(sentence: "browser_click_at needs x and y")
            }
            return try await automation.clickAt(x: xPoint, y: yPoint).rendered()
        default:
            return nil
        }
    }

    private func waitCondition(_ args: Arguments) throws -> BrowserWaitCondition {
        if let text = args.optionalString("text") { return .text(text) }
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
        // A private pane's title and address are the page's words, so they
        // are concealed here as everywhere else; one whose words cannot be
        // read shows neither.
        let rows: [[String: Any]] = panes.map { pane in
            [
                "id": pane.id, "title": pane.agentPrivacy.concealing(pane.title),
                "url": pane.agentPrivacy.concealing(pane.url), "project": pane.project,
                "tab": pane.tab, "engine": pane.engine.rawValue, "is_default": pane.id == defaultID,
                "access": Self.accessName(pane.access), "agent_privacy": pane.agentPrivacy.isOn
            ]
        }
        let data = (try? JSONSerialization.data(withJSONObject: rows, options: [.sortedKeys])) ?? Data()
        return String(bytes: data, encoding: .utf8) ?? ""
    }

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
        tool("browser_list", "List the open Browser panes: id, title, url, project, tab, engine (safari or chrome), access (full, or read only: snapshot, find, text, console, screenshot and wait only), and which one is the default for this caller.", [:]),
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
            "scope": ToolJSONSchema.string("A ref or CSS selector to snapshot under"),
            "include_urls": ToolJSONSchema.boolean("Add [url=…] to links"),
            "delta": ToolJSONSchema.boolean("Only what changed since the last snapshot, in page order: lines added (with refs), lines removed, and lines renumbered (same line, new ref)")
        ]),
        tool("browser_text", "The visible text of the page (its main region, else the whole body).", ["pane_id": paneID, "scope": ToolJSONSchema.string("A ref or CSS selector")]),
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
        tool("browser_screenshot", "A PNG of the viewport, or of one element by ref. Its pixels are the coordinates browser_click_at takes.", refGen),
        tool("browser_click_at", "A real mouse click at a point of the last browser_screenshot, in that image's pixels. Take a screenshot first; browser_click by ref is the usual way.", ["pane_id": paneID, "x": ToolJSONSchema.number("Pixels from the left edge of the last screenshot"), "y": ToolJSONSchema.number("Pixels from the top edge of the last screenshot")], required: ["x", "y"]),
        tool("browser_console", "The page's last console messages and errors.", ["pane_id": paneID, "level": ToolJSONSchema.string("log, info, warn, error or debug")]),
        tool("browser_evaluate", "Evaluate a JavaScript expression in the page and return its JSON. Off unless enabled in Settings.", ["pane_id": paneID, "expression": ToolJSONSchema.string("The expression")], required: ["expression"])
    ]
    // swiftlint:enable line_length
}
