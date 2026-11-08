// swiftlint:disable line_length identifier_name
import AppKit
import Combine
import WebKit

public struct BrowserDialog: Sendable, Equatable {
    public enum Kind: String, Sendable { case alert, confirm, prompt }
    public var kind: Kind
    public var message: String

    public init(kind: Kind, message: String) {
        self.kind = kind
        self.message = message
    }
}

/// What changed because of one action.
public struct BrowserActionDelta: Sendable {
    public var url: String?
    public var title: String?
    public var navigated = false
    public var pending = false
    public var changed = false
    public var focused: String?
    public var dialog: BrowserDialog?

    public func rendered() -> String {
        var lines: [String] = []
        if navigated {
            lines.append("navigated to \(url ?? "?") — \(title ?? "")")
        } else {
            if let url { lines.append("url: \(url)") }
            if let title { lines.append("title: \(title)") }
        }
        if pending { lines.append("a navigation is still in progress; call browser_wait_for load") }
        if let dialog { lines.append("dialog (\(dialog.kind.rawValue), dismissed): \(dialog.message)") }
        if let focused { lines.append(focused) }
        if lines.isEmpty { return changed ? "changed" : "no visible change" }
        return lines.joined(separator: "\n")
    }
}

public enum BrowserWaitCondition: Sendable, Equatable {
    case text(String)
    case ref(String, generation: Int)
    case url(String)
    case load
    case idle

    var description: String {
        switch self {
        case .text(let needle): return "text \"\(needle)\""
        case .ref(let ref, _): return "ref \(ref)"
        case .url(let fragment): return "url containing \"\(fragment)\""
        case .load: return "load"
        case .idle: return "idle"
        }
    }
}

public struct BrowserWaitResult: Sendable {
    public var satisfied: Bool
    public var url: String
    public var title: String
}

public struct BrowserFindMatch: Sendable, Equatable {
    public var ref: String
    public var role: String
    public var name: String
}

/// The automations the current call chain is already driving, so a nested
/// `drive` from inside one can tell itself apart from a second caller.
enum BrowserDriveChain {
    @TaskLocal static var held: Set<ObjectIdentifier> = []
}

/// Resumes a continuation exactly once: with WebKit's answer, or with the
/// timeout, whichever comes first. WebKit's callbacks cannot be cancelled, so
/// whichever arrives second finds the continuation gone and is dropped.
@MainActor
private final class Resumer<Value> {
    var continuation: CheckedContinuation<Value, Error>?
    var timer: Task<Void, Never>?

    func finish(_ result: sending Result<Value, Error>) {
        guard let continuation else { return }
        self.continuation = nil
        timer?.cancel()
        continuation.resume(with: result)
    }
}

/// Drives one page on behalf of a model, through whichever engine renders it.
@MainActor
public final class BrowserAutomation: NSObject {
    public static let defaultTimeout: TimeInterval = 10
    public static let maximumTimeout: TimeInterval = 60
    public static let maximumScreenshotSide: CGFloat = 1568

    /// The page being driven. Replaced, never mutated, when the pane rebuilds
    /// its engine onto another storage jar — see `retarget(to:)`.
    public private(set) var driver: BrowserPageDriver
    public let console: BrowserConsoleLog
    /// Whether the page's console is being captured at all. Set by the pane
    /// from the Capture Page Console setting it built the current web view
    /// with, so the console tool can say capture is off rather than report
    /// an empty console as a quiet page.
    public var isConsoleCaptureOn = true

    public private(set) var isActionInFlight = false
    public var onDriveStateChange: ((Bool) -> Void)?
    /// Told after every action: its name (`click`, `navigate`, …) and whether
    /// it succeeded. The pane's event log (spec section 12) reads this.
    public var onAction: ((String, Bool) -> Void)?

    private var driveDepth = 0
    private var pendingDialog: BrowserDialog?
    private var loadObservation: AnyCancellable?
    private var navigationsStarted = 0
    private var navigationsFinished = 0

    public init(driver: BrowserPageDriver, console: BrowserConsoleLog) {
        self.driver = driver
        self.console = console
        super.init()
        observeLoading()
    }

    /// Points the automation at a new page: the pane's handle, the model's
    /// tools and the drive badge all reach the page through this one object,
    /// so a pane that swaps its engine moves them all by moving this.
    public func retarget(to driver: BrowserPageDriver) {
        guard driver !== self.driver else { return }
        self.driver = driver
        observeLoading()
    }

    private func observeLoading() {
        loadObservation = driver.loadingChanges.sink { [weak self] started in
            Task { @MainActor in
                guard let self else { return }
                if started { self.navigationsStarted += 1 } else { self.navigationsFinished += 1 }
            }
        }
    }

    /// Drives a bare web view whose delegates are someone else's.
    public convenience init(webView: WKWebView, console: BrowserConsoleLog) {
        self.init(driver: WebKitPageDriver(webView: webView), console: console)
    }

    public var currentURL: String { driver.url?.absoluteString ?? "about:blank" }
    public var currentTitle: String { driver.title ?? "" }

    /// Whether this URL is one a model may drive. Local files are never
    /// driven: the user's own disk is not the model's to read through a pane.
    public static func isDrivable(_ url: String) -> Bool {
        !url.lowercased().hasPrefix("file:")
    }

    /// Throws when the page now showing is a local file. Every runtime call
    /// and every action checks this at the moment it runs, not when it was
    /// queued, so a page that became a local file while the call waited at
    /// the gate (a back or forward that landed on one, say) is refused too.
    public func ensureDrivable() throws {
        guard Self.isDrivable(currentURL) else { throw BrowserAutomationError.localFile }
    }

    // MARK: Driving

    /// Every tool call runs inside this so the pane can show its badge and
    /// route dialogs here.
    ///
    /// One caller at a time: the outermost `drive` takes a FIFO gate and holds
    /// it until its body finishes, so a second caller — another Claude Code
    /// process, a persona chat — waits its turn instead of interleaving with
    /// the first at every `await`. An action's dialog and delta then belong to
    /// the caller that caused them. Re-entrant within one call chain: a task
    /// local records which automations the current chain already holds, and a
    /// nested `drive` from that chain passes straight through. The depth count
    /// alone cannot tell the two apart, because a second caller also sees a
    /// non-zero depth while the first is inside. A caller cancelled while it
    /// waits still takes its turn, so the queue stays in order, but then
    /// throws `CancellationError` without running its body: a cancelled tool
    /// call must not act on the page after its caller has gone.
    public func drive<T>(_ body: () async throws -> T) async throws -> T {
        let key = ObjectIdentifier(self)
        if BrowserDriveChain.held.contains(key) { return try await counted(body) }
        await acquireGate()
        defer { releaseGate() }
        try Task.checkCancellation()
        return try await BrowserDriveChain.$held.withValue(BrowserDriveChain.held.union([key])) {
            try await counted(body)
        }
    }

    private var gateHeld = false
    private var gateWaiters: [CheckedContinuation<Void, Never>] = []
    /// How many calls are waiting at the gate. For tests: how a test knows a
    /// call is queued, rather than sleeping and hoping it is.
    var queuedCallCount: Int { gateWaiters.count }

    private func acquireGate() async {
        guard gateHeld else {
            gateHeld = true
            return
        }
        await withCheckedContinuation { gateWaiters.append($0) }
    }

    /// Hands the gate straight to the first waiter, which then holds it, so a
    /// caller arriving between the release and the waiter's resumption cannot
    /// jump the queue.
    private func releaseGate() {
        if gateWaiters.isEmpty {
            gateHeld = false
        } else {
            gateWaiters.removeFirst().resume()
        }
    }

    private func counted<T>(_ body: () async throws -> T) async rethrows -> T {
        driveDepth += 1
        if driveDepth == 1 { isActionInFlight = true; onDriveStateChange?(true) }
        defer {
            driveDepth -= 1
            if driveDepth == 0 { isActionInFlight = false; onDriveStateChange?(false) }
        }
        return try await body()
    }

    /// Called by the pane's `WKUIDelegate` while an action is in flight.
    public func dialogRaised(kind: BrowserDialog.Kind, message: String) {
        pendingDialog = BrowserDialog(kind: kind, message: message)
    }

    // MARK: Runtime calls

    private func call(_ function: String, _ ordered: KeyValuePairs<String, Any> = [:]) async throws -> Any? {
        try ensureDrivable()
        try await driver.installAutomationRuntime()
        // Positional order matters to the JS functions, so keep the caller's order.
        let names = ordered.map(\.key)
        var arguments: [String: Any] = [:]
        for (key, value) in ordered { arguments[key] = value }
        let body = "return window.__adkitchen.\(function)(\(names.joined(separator: ", ")))"
        let raw: Any?
        do {
            raw = try await driver.callAsyncFunction(body: body, arguments: arguments, world: .automation)
        } catch let error as BrowserAutomationError {
            // Already the model's vocabulary; rewrapping it through
            // `localizedDescription` would lose the message.
            throw error
        } catch {
            throw BrowserAutomationError.script(error.localizedDescription)
        }
        if let envelope = raw as? [String: Any], let error = envelope["error"] as? String {
            switch error {
            case "stale": throw BrowserAutomationError.staleRef
            case "unknown": throw BrowserAutomationError.unknownRef(arguments["ref"] as? String ?? "?")
            default: throw BrowserAutomationError.script(error.replacingOccurrences(of: "script: ", with: ""))
            }
        }
        if let envelope = raw as? [String: Any], envelope.keys.contains("ok") { return envelope["ok"] }
        return raw
    }

    // MARK: Reading

    public func snapshot(_ options: BrowserSnapshotOptions) async throws -> BrowserSnapshot {
        let raw = try await call("snapshot", ["opts": options.jsArguments])
        // `JSONSerialization.data` raises an Objective-C exception, not a Swift
        // error, on anything that is not JSON (a NaN, a Date), so check first.
        guard JSONSerialization.isValidJSONObject(raw as Any) else {
            throw BrowserAutomationError.script("the snapshot is not JSON")
        }
        let data = try JSONSerialization.data(withJSONObject: raw as Any)
        let payload = try JSONDecoder().decode(BrowserSnapshotPayload.self, from: data)
        var snapshot = BrowserSnapshot(payload: payload, includeURLs: options.includeURLs)
        if options.delta, let previous = lastSnapshotLines {
            snapshot.text = Self.delta(from: previous, to: snapshot.text)
        }
        lastSnapshotLines = BrowserSnapshot(payload: payload, includeURLs: options.includeURLs).text
            .split(separator: "\n").map(String.init)
        return snapshot
    }

    private var lastSnapshotLines: [String]?

    /// What changed between two snapshots, in page order. Lines are matched on
    /// their text with the ref stripped, through a longest-common-subsequence
    /// alignment, so a second copy of a line is an addition, a reorder is a
    /// removal and an addition, and a line whose only change is its ref is
    /// reported under "Renumbered:" with the ref to use now. A set comparison
    /// saw none of those and called them all "no change".
    static func delta(from previous: [String], to current: String) -> String {
        let now = current.split(separator: "\n").map(String.init)
        let strip: (String) -> String = {
            $0.replacingOccurrences(of: #" \[ref=e\d+\]"#, with: "", options: .regularExpression)
        }
        let before = previous.map(strip), after = now.map(strip)
        var added: [String] = [], removed: [String] = [], renumbered: [String] = []
        for step in Self.align(before, after) {
            switch step {
            case .matched(let i, let j): if previous[i] != now[j] { renumbered.append(now[j]) }
            case .removed(let i): removed.append(before[i])
            case .added(let j): added.append(now[j])
            }
        }
        if added.isEmpty && removed.isEmpty && renumbered.isEmpty { return "no change since the last snapshot\n" }
        var out = ""
        if !added.isEmpty { out += "Added:\n" + added.joined(separator: "\n") + "\n" }
        if !removed.isEmpty { out += "Removed:\n" + removed.joined(separator: "\n") + "\n" }
        if !renumbered.isEmpty { out += "Renumbered:\n" + renumbered.joined(separator: "\n") + "\n" }
        return out
    }

    enum AlignmentStep: Equatable {
        case matched(Int, Int)
        case removed(Int)
        case added(Int)
    }

    /// An ordered longest-common-subsequence alignment of two line lists. The
    /// common prefix and suffix are matched first, since a page change is
    /// almost always local, and the middle is aligned by dynamic programming.
    /// A middle too large for the table is reported as a wholesale
    /// replacement: verbose, never wrong.
    static func align(_ a: [String], _ b: [String]) -> [AlignmentStep] {
        var out: [AlignmentStep] = []
        var start = 0
        while start < a.count, start < b.count, a[start] == b[start] {
            out.append(.matched(start, start))
            start += 1
        }
        var endA = a.count, endB = b.count
        while endA > start, endB > start, a[endA - 1] == b[endB - 1] {
            endA -= 1
            endB -= 1
        }
        let n = endA - start, m = endB - start, width = m + 1
        if n * m > 4_000_000 {
            for i in start..<endA { out.append(.removed(i)) }
            for j in start..<endB { out.append(.added(j)) }
        } else if n > 0 || m > 0 {
            // table[i * width + j]: the LCS length of a[start + i...] and b[start + j...].
            var table = [Int](repeating: 0, count: (n + 1) * width)
            for i in stride(from: n - 1, through: 0, by: -1) {
                for j in stride(from: m - 1, through: 0, by: -1) {
                    table[i * width + j] = a[start + i] == b[start + j]
                        ? table[(i + 1) * width + j + 1] + 1
                        : max(table[(i + 1) * width + j], table[i * width + j + 1])
                }
            }
            var i = 0, j = 0
            while i < n || j < m {
                if i < n, j < m, a[start + i] == b[start + j] {
                    out.append(.matched(start + i, start + j))
                    i += 1
                    j += 1
                } else if j < m, i == n || table[i * width + j + 1] >= table[(i + 1) * width + j] {
                    out.append(.added(start + j))
                    j += 1
                } else {
                    out.append(.removed(start + i))
                    i += 1
                }
            }
        }
        for k in 0..<(a.count - endA) { out.append(.matched(endA + k, endB + k)) }
        return out
    }

    public func find(_ text: String) async throws -> [BrowserFindMatch] {
        let raw = try await call("find", ["text": text]) as? [[String: Any]] ?? []
        return raw.compactMap { match in
            guard let ref = match["ref"] as? String else { return nil }
            return BrowserFindMatch(ref: ref, role: match["role"] as? String ?? "generic",
                                    name: match["name"] as? String ?? "")
        }
    }

    public func text(scope: String?) async throws -> String {
        try await call("text", ["scope": scope ?? NSNull()]) as? String ?? ""
    }

    // MARK: Actions

    public func click(ref: String, generation: Int, native: Bool) async throws -> BrowserActionDelta {
        try await act("click") {
            if native {
                let r = try await self.rect(ref: ref, generation: generation)
                try await self.nativeClick(atViewportX: r.midX, viewportY: r.midY)
            } else {
                _ = try await self.call("click", ["ref": ref, "gen": generation])
            }
        }
    }

    public func type(ref: String, generation: Int, text: String, submit: Bool) async throws -> BrowserActionDelta {
        try await act("type") { _ = try await self.call("type", ["ref": ref, "gen": generation, "text": text, "submit": submit]) }
    }

    public func fill(ref: String, generation: Int, value: String) async throws -> BrowserActionDelta {
        try await act("fill") { _ = try await self.call("fill", ["ref": ref, "gen": generation, "value": value]) }
    }

    public func select(ref: String, generation: Int, value: String) async throws -> BrowserActionDelta {
        try await act("select") { _ = try await self.call("select", ["ref": ref, "gen": generation, "value": value]) }
    }

    public func hover(ref: String, generation: Int) async throws -> BrowserActionDelta {
        try await act("hover") { _ = try await self.call("hover", ["ref": ref, "gen": generation]) }
    }

    public func pressKey(_ key: String) async throws -> BrowserActionDelta {
        try await act("pressKey") { _ = try await self.call("pressKey", ["spec": key]) }
    }

    public func scroll(ref: String?, generation: Int?, direction: String?, amount: Int?) async throws -> BrowserActionDelta {
        try await act("scroll") {
            _ = try await self.call("scroll", ["ref": ref ?? NSNull(), "gen": generation ?? NSNull(),
                                               "direction": direction ?? "down", "amount": amount ?? NSNull()])
        }
    }

    /// Where the last screenshot's pixels sit in the viewport: a screenshot is
    /// device pixels, capped to `maximumScreenshotSide` and cropped to an
    /// element when a ref was given, so a point read off it is neither CSS
    /// pixels nor viewport-relative until it is mapped through this.
    struct ScreenshotFrame: Equatable, Sendable {
        /// CSS pixels per image pixel.
        var scale: Double
        /// The image's top-left corner, in viewport CSS pixels.
        var origin: CGPoint

        func viewportPoint(imageX x: Double, imageY y: Double) -> CGPoint {
            CGPoint(x: origin.x + x * scale, y: origin.y + y * scale)
        }
    }

    private(set) var lastScreenshot: ScreenshotFrame?

    /// A real click at a point of the last screenshot, in that image's pixels.
    /// Without a screenshot there is nothing the coordinates could be read
    /// off, so the call is refused rather than guessed at.
    public func clickAt(x: Double, y: Double) async throws -> BrowserActionDelta {
        guard let frame = lastScreenshot else { throw BrowserAutomationError.noScreenshot }
        let point = frame.viewportPoint(imageX: x, imageY: y)
        return try await act("clickAt") { try await self.nativeClick(atViewportX: point.x, viewportY: point.y) }
    }

    /// Runs `expression` as the body `return (<expression>);` of an async
    /// function, so a returned Promise is awaited before the value comes back,
    /// and renders the value as JSON (`undefined` when there is none).
    ///
    /// The newlines around the expression keep a trailing `//` comment from
    /// swallowing the closing parenthesis, and one trailing semicolon is
    /// dropped first, since `return (x;)` is a syntax error and a model
    /// writing `document.title;` means the expression, not a statement.
    ///
    /// Gives up after `maximumTimeout`: the caller holds the pane's drive
    /// gate throughout, and a promise that never settles would otherwise hold
    /// it for good, queueing every later tool call on the pane behind it.
    /// WebKit cannot be told to stop, so its answer, if it ever comes, is
    /// dropped.
    public func evaluate(_ expression: String) async throws -> String {
        try ensureDrivable()
        let body = "return (\n\(Self.expressionBody(expression))\n);"
        let once = Resumer<String>()
        let timeout = Self.maximumTimeout
        do {
            return try await withCheckedThrowingContinuation { c in
                once.continuation = c
                once.timer = Task { @MainActor in
                    try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                    guard !Task.isCancelled else { return }
                    once.finish(.failure(BrowserAutomationError.timeout("the expression (\(Int(timeout)) s)")))
                }
                Task { @MainActor in
                    do {
                        let value = try await self.driver.callAsyncFunction(body: body, arguments: [:], world: .page)
                        once.finish(.success(Self.renderJSON(value)))
                    } catch {
                        once.finish(.failure(error))
                    }
                }
            }
        } catch let error as BrowserAutomationError {
            throw error
        } catch {
            let message = Self.javaScriptMessage(of: error)
            if Self.isContentSecurityPolicyRefusal(message) { throw BrowserAutomationError.cspRefusesEvaluation }
            throw BrowserAutomationError.script(message)
        }
    }

    /// The expression with surrounding whitespace and one trailing `;` removed.
    static func expressionBody(_ expression: String) -> String {
        var body = expression.trimmingCharacters(in: .whitespacesAndNewlines)
        if body.hasSuffix(";") {
            body.removeLast()
            body = body.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return body
    }

    /// What WebKit says went wrong: the page's exception message when there
    /// is one, else the error's own description.
    static func javaScriptMessage(of error: Error) -> String {
        let info = (error as NSError).userInfo
        if let message = info["WKJavaScriptExceptionMessage"] as? String, !message.isEmpty { return message }
        return error.localizedDescription
    }

    /// An `EvalError`, or a refusal that names the policy.
    static func isContentSecurityPolicyRefusal(_ message: String) -> Bool {
        let lowered = message.lowercased()
        return lowered.contains("evalerror") || lowered.contains("content security policy")
            || lowered.contains("unsafe-eval")
    }

    /// JSON for a value WebKit handed back. `nil` is JavaScript's `undefined`;
    /// a bare string or number is rendered as a JSON fragment. A value that is
    /// not JSON at all — NaN, Infinity, a Date — is described instead:
    /// `JSONSerialization.data` raises an Objective-C exception on it, which
    /// `try?` cannot catch, so the check comes first. Wrapping the value in an
    /// array lets `isValidJSONObject` answer for a fragment too.
    static func renderJSON(_ value: Any?) -> String {
        guard let value else { return "undefined" }
        if value is NSNull { return "null" }
        guard JSONSerialization.isValidJSONObject([value]),
              let data = try? JSONSerialization.data(withJSONObject: value, options: [.fragmentsAllowed, .sortedKeys]),
              let text = String(data: data, encoding: .utf8) else { return String(describing: value) }
        return text
    }

    public func navigate(to url: URL) async throws -> BrowserActionDelta {
        try await act("navigate") { self.driver.load(url) }
    }

    public func goBack() async throws -> BrowserActionDelta { try await act("goBack") { self.driver.goBack() } }
    public func goForward() async throws -> BrowserActionDelta { try await act("goForward") { self.driver.goForward() } }

    /// Runs one action, reports it to `onAction` by name and outcome, and
    /// returns its delta.
    private func act(_ name: String, _ body: () async throws -> Void) async throws -> BrowserActionDelta {
        do {
            let delta = try await gatherDelta(body)
            onAction?(name, true)
            return delta
        } catch {
            onAction?(name, false)
            throw error
        }
    }

    /// Gathers one action's delta: arm the mutation counter and navigation
    /// counters, act, wait 300 ms, read what moved.
    private func gatherDelta(_ body: () async throws -> Void) async throws -> BrowserActionDelta {
        try ensureDrivable()
        let urlBefore = currentURL, titleBefore = currentTitle
        let startedBefore = navigationsStarted, finishedBefore = navigationsFinished
        let mutationsBefore = (try? await call("mutations") as? Int) ?? 0
        pendingDialog = nil
        try await body()
        try await Task.sleep(nanoseconds: 300_000_000)
        var delta = BrowserActionDelta()
        delta.dialog = pendingDialog
        pendingDialog = nil
        if navigationsStarted > startedBefore || driver.isLoading {
            let deadline = Date().addingTimeInterval(Self.defaultTimeout)
            while driver.isLoading && Date() < deadline { try await Task.sleep(nanoseconds: 100_000_000) }
            if driver.isLoading { delta.pending = true } else { delta.navigated = navigationsFinished > finishedBefore }
            lastSnapshotLines = nil
            // A back or forward can land on a local file the pane once
            // showed. Nothing below may run against it, the runtime least of
            // all, so the landing is reported as the refusal it is.
            try ensureDrivable()
        }
        // A #fragment navigation leaves `navigated` false; this URL diff still reports it.
        if currentURL != urlBefore { delta.url = currentURL }
        if currentTitle != titleBefore { delta.title = currentTitle }
        if delta.navigated { delta.url = currentURL; delta.title = currentTitle }
        let mutationsAfter = (try? await call("mutations") as? Int) ?? mutationsBefore
        delta.changed = delta.navigated || mutationsAfter != mutationsBefore
        if delta.changed && !delta.navigated && !delta.pending,
           let ref = try? await call("focusedLandmark") as? String,
           let raw = try? await call("landmarkSnapshot", ["ref": ref, "depth": 4]),
           JSONSerialization.isValidJSONObject(raw as Any),
           let data = try? JSONSerialization.data(withJSONObject: raw as Any),
           let node = try? JSONDecoder().decode(BrowserSnapshotNode.self, from: data) {
            delta.focused = BrowserSnapshotRenderer.render(node, includeURLs: false)
        }
        return delta
    }

    // MARK: Waiting

    public func wait(for condition: BrowserWaitCondition, timeout: TimeInterval?) async throws -> BrowserWaitResult {
        let limit = min(max(timeout ?? Self.defaultTimeout, 0.05), Self.maximumTimeout)
        let deadline = Date().addingTimeInterval(limit)
        var idleSince: Date?
        var lastMutations = -1
        while Date() < deadline {
            let satisfied: Bool
            switch condition {
            case .text(let t): satisfied = (try? await call("hasText", ["needle": t]) as? Bool) ?? false
            case .ref(let r, let g): satisfied = (try? await call("isVisible", ["ref": r, "gen": g]) as? Bool) ?? false
            case .url(let u): satisfied = currentURL.contains(u)
            case .load: satisfied = !driver.isLoading && driver.url != nil
            case .idle:
                let m = (try? await call("mutations") as? Int) ?? -2
                if m != lastMutations { lastMutations = m; idleSince = Date() }
                satisfied = !driver.isLoading && idleSince.map { Date().timeIntervalSince($0) >= 0.5 } == true
            }
            if satisfied { return BrowserWaitResult(satisfied: true, url: currentURL, title: currentTitle) }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        throw BrowserAutomationError.timeout(condition.description)
    }

    // MARK: Geometry, screenshots, native events

    private func rect(ref: String, generation: Int) async throws -> CGRect {
        guard let r = try await call("rect", ["ref": ref, "gen": generation]) as? [String: Double] else {
            throw BrowserAutomationError.script("no rect for \(ref)")
        }
        return CGRect(x: r["x"] ?? 0, y: r["y"] ?? 0, width: r["width"] ?? 0, height: r["height"] ?? 0)
    }

    /// Resamples so the longer side is at most `side` PIXELS (not points: a Retina
    /// snapshot of an 800 pt view is 1600 px).
    static func capped(_ image: CGImage, side: CGFloat) -> CGImage? {
        let longest = CGFloat(max(image.width, image.height))
        guard longest > side else { return image }
        let scale = side / longest
        let width = max(1, Int((CGFloat(image.width) * scale).rounded()))
        let height = max(1, Int((CGFloat(image.height) * scale).rounded()))
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()
    }

    /// How long the engine's snapshot may take before the screenshot is given up.
    public static let screenshotTimeout: TimeInterval = 10

    /// Refuses a pane whose view is in no window or in one that is not
    /// visible, and gives up after `screenshotTimeout`: a pane the engine has
    /// stopped painting can otherwise leave the snapshot without an answer.
    /// Occlusion is deliberately not checked — a quiet-presentation window is
    /// occluded by design and still screenshots.
    public func screenshot(ref: String?, generation: Int?) async throws -> Data {
        guard let window = driver.view.window, window.isVisible else { throw BrowserAutomationError.notOnScreen }
        // The viewport, or the element's rect, in CSS pixels: what the image shows.
        var shown = CGRect(origin: .zero, size: driver.viewportSize)
        var clip: CGRect?
        if let ref, let generation {
            shown = try await rect(ref: ref, generation: generation)
            clip = shown
        }
        let once = Resumer<CGImage>()
        let timeout = Self.screenshotTimeout
        let driver = self.driver
        let full: CGImage = try await withCheckedThrowingContinuation { c in
            once.continuation = c
            once.timer = Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                guard !Task.isCancelled else { return }
                once.finish(.failure(BrowserAutomationError.screenshotTimedOut))
            }
            Task { @MainActor in
                do {
                    once.finish(.success(try await driver.snapshot(cssRect: clip)))
                } catch let error as BrowserAutomationError {
                    once.finish(.failure(error))
                } catch {
                    once.finish(.failure(BrowserAutomationError.script(error.localizedDescription)))
                }
            }
        }
        guard let cg = Self.capped(full, side: Self.maximumScreenshotSide),
              let png = NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:]) else {
            throw BrowserAutomationError.script("could not encode the screenshot")
        }
        if cg.width > 0, shown.width > 0 {
            lastScreenshot = ScreenshotFrame(scale: shown.width / Double(cg.width), origin: shown.origin)
        }
        return png
    }

    /// A real click at a viewport point in CSS pixels, through the engine.
    /// Viewport, not page, coordinates: a page coordinate would be off by the
    /// scroll offset on any page that has scrolled.
    private func nativeClick(atViewportX x: Double, viewportY y: Double) async throws {
        try await driver.nativeClick(atViewportX: x, viewportY: y)
    }
}
// swiftlint:enable line_length identifier_name
