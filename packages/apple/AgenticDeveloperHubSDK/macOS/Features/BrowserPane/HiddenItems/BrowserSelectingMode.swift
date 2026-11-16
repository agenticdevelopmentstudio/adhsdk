//
//  BrowserSelectingMode.swift
//  AgenticDeveloperHubSDK
//

import AgenticDeveloperHubSDKCore
import AppKit
import OSLog
import WebKit

/// Where the agent list's picker runs in the Agent preview (recipe
/// `workspace/browser/hide-from-agent`): the preview's web view, the agent
/// page it shows, and a hook for each new document it loads.
@MainActor
protocol BrowserAgentPickSurface: AnyObject {
    var pickWebView: WKWebView { get }
    /// The agent page on screen, which a pick's `data-adk-ref` resolves against.
    var shownPage: AgentPage? { get }
    /// Called when a new document finishes loading; the picker it held is gone.
    var onPageLoad: (() -> Void)? { get set }
}

/// One pane's selecting mode (recipe `workspace/browser/element-picker`):
/// the picker on its front page, the stop icon on the address-bar button,
/// Esc to leave, and the pick dialog for each accepted pick.
///
/// `idle → selecting` on `begin()`; `selecting → dialog` on an accepted
/// pick, which pauses the picker; `dialog → selecting` on OK or Cancel;
/// `selecting | dialog → idle` through `end(_:)`, the one routine every exit
/// (stop, Esc, the page's `cancel`, navigation, tab switch, close) goes
/// through, so the outline, listeners, handler and preview always go with it.
/// The list it writes to is a parameter, so the agent list reuses it.
///
/// With a `preview` surface (recipe `workspace/browser/hide-from-agent`) the
/// picker runs in the Agent preview instead of on the live page: a pick is
/// mapped through its `data-adk-ref` to the selector the agent page recorded
/// for that node, and a pick with no such ref is refused.
@MainActor
final class BrowserSelectingMode {

    enum State: Equatable {
        case idle
        case selecting
        case dialog(BrowserPickCandidate)
    }

    /// Which of the pane's views the picker runs in, for the log.
    enum View: String {
        case website = "Website"
        case agentPreview = "Agent preview"
    }

    /// Why selecting ended, for the log.
    enum EndReason: String {
        case stop
        case escape = "Esc"
        case navigation
        case tabSwitch = "tab switch"
        case viewSwitch = "view switch"
        case close
        case failure
    }

    static let noticeText = "Items that load again (such as ads) can reappear."

    /// Shows a pick's dialog. The default runs it modally on the next turn
    /// of the main loop, out of the WebKit callback the pick arrived in; a
    /// test captures it instead.
    typealias DialogPresenter = @MainActor (BrowserPickDialogController, NSWindow?) -> Void
    /// Shows the first-use notice over `window`.
    typealias NoticePresenter = @MainActor (NSWindow?) -> Void

    private(set) var state: State = .idle
    let list: BrowserHiddenItemList
    let view: View
    private(set) weak var engine: WebKitBrowserEngine?
    /// The Agent preview the picker runs in; `nil` for the Website view.
    private(set) weak var preview: (any BrowserAgentPickSurface)?
    private let store: BrowserHiddenItemsStore
    private let button: BrowserHideItemsButton
    /// The global layer: the notice key is global only.
    private let settings: SettingsStore
    private let presentDialog: DialogPresenter
    private let presentNotice: NoticePresenter
    private(set) var picker: BrowserElementPicker?
    /// The last picker start, which the next one waits for; a test can too.
    private(set) var startTask: Task<Void, Never>?
    private var dialog: BrowserPickDialogController?
    private var keyMonitor: Any?
    /// The page's address when the pick arrived; what the entry's site is
    /// derived from.
    private var pickURL: URL?
    /// The preview pick's ref, which the dialog's preview hides in the
    /// Agent preview's own markup.
    private var pickRef: String?
    /// The preview rule set last asked for; nil when there is none.
    private(set) var previewSelectors: [String]?
    /// The last save started, so a test can wait for it.
    private(set) var lastSave: Task<Void, Never>?
    private static let logger = Logger(subsystem: "AgenticDeveloperHubSDK", category: "BrowserPane")

    init(engine: WebKitBrowserEngine, store: BrowserHiddenItemsStore, list: BrowserHiddenItemList,
         button: BrowserHideItemsButton, preview: (any BrowserAgentPickSurface)? = nil,
         settings: SettingsStore = UserSettings.shared,
         presentDialog: DialogPresenter? = nil, presentNotice: NoticePresenter? = nil) {
        self.engine = engine
        self.store = store
        self.list = list
        self.button = button
        self.preview = preview
        view = preview == nil ? .website : .agentPreview
        self.settings = (settings as? LayeredSettingsStore)?.fallback ?? settings
        self.presentDialog = presentDialog ?? Self.runModalDialog
        self.presentNotice = presentNotice ?? Self.showNotice
    }

    var isActive: Bool { state != .idle }

    /// The web view picks are made in: the live page's, or the preview's.
    var pickWebView: WKWebView? {
        switch view {
        case .website: return engine?.webView
        case .agentPreview: return preview?.pickWebView
        }
    }

    // MARK: - Starting and ending

    /// Starts selecting on the engine's page (or in the preview). Starting
    /// while selecting (or with the dialog up) does nothing, so a pane never
    /// has two pickers.
    func begin() {
        guard state == .idle, let webView = pickWebView else { return }
        guard Self.canSelect(on: engine?.url) else {
            NSSound.beep()
            return
        }
        state = .selecting
        button.showSelecting(true)
        showNoticeIfFirstUse(in: webView.window)
        installKeyMonitor()
        preview?.onPageLoad = { [weak self] in self?.reinstallPicker() }
        installPicker(on: webView)
        let place = logPlace
        Self.logger.info("selecting mode started on \(place, privacy: .public)")
    }

    /// Whether a pick on `url` can be saved for its own site. A page with no
    /// host (`file:`, `about:`, `data:`) has no site to scope an entry to:
    /// its default pattern is `*`, which would hide the item on every page.
    nonisolated static func canSelect(on url: URL?) -> Bool {
        PrivacySitePattern.defaultPattern(for: url) != PrivacySitePattern.everywhere
    }

    /// A new picker on `webView`, started after the previous start so two
    /// pickers never install at once in the one content world they share.
    private func installPicker(on webView: WKWebView) {
        let picker = BrowserElementPicker(
            webView: webView, list: list,
            onPick: { [weak self] candidate in self?.handlePick(candidate) },
            onCancel: { [weak self] in self?.end(.escape) })
        self.picker = picker
        let previous = startTask
        startTask = Task { [weak self] in
            await previous?.value
            // Ended before the start could run: install nothing.
            guard let self, self.picker === picker else { return }
            do {
                try await picker.start()
            } catch {
                // The picker could not run (in the preview, a world WebKit
                // would not run with page JavaScript off): say so.
                if self.picker === picker {
                    NSSound.beep()
                    self.end(.failure)
                }
                return
            }
            // Ended while the start was in flight: take the stray picker down.
            guard self.picker === picker else { return picker.stop() }
            // A document reloaded under the dialog: keep the picker paused
            // and the dialog's preview showing.
            if case .dialog = self.state {
                picker.pause()
                if let selectors = self.previewSelectors { self.setPreview(selectors) }
            }
        }
    }

    /// The preview loaded a new document (a refresh after OK, a setting
    /// change), which took the picker's script with it: install a new one.
    private func reinstallPicker() {
        guard state != .idle, let webView = pickWebView else { return }
        picker?.stop()
        installPicker(on: webView)
    }

    /// Ends selecting for `reason`: closes the dialog without saving, stops
    /// the picker (outline, listeners, handler) and clears the preview.
    func end(_ reason: EndReason) {
        guard state != .idle else { return }
        state = .idle
        let openDialog = dialog
        dialog = nil
        openDialog?.dismiss()
        picker?.stop()
        picker = nil
        preview?.onPageLoad = nil
        removeKeyMonitor()
        setPreview(nil)
        pickURL = nil
        pickRef = nil
        button.showSelecting(false)
        let place = logPlace
        Self.logger.info("selecting mode ended (\(reason.rawValue, privacy: .public)) on \(place, privacy: .public)")
    }

    // MARK: - Picks and the dialog

    /// An accepted pick: pause the picker and open the dialog for it. In the
    /// Agent preview the pick is first mapped to its node's recorded selector.
    func handlePick(_ candidate: BrowserPickCandidate) {
        guard state == .selecting, candidate.thisItemAccepted else { return }
        var accepted = candidate
        if view == .agentPreview {
            let page = preview?.shownPage
            guard let mapped = Self.mapPreviewPick(candidate, in: page) else {
                let place = logPlace
                Self.logger.info("element pick refused on \(place, privacy: .public)")
                NSSound.beep()
                return
            }
            accepted = mapped
            pickRef = candidate.ref
            // The site comes from the live page, never from `AgentPage.url`:
            // that is the concealed address, and an entry saved under a
            // stand-in host would never apply. A commit ends selecting, so
            // the engine's URL is the page the preview was built from.
        }
        picker?.pause()
        state = .dialog(accepted)
        pickURL = engine?.url
        let controller = BrowserPickDialogController(
            candidate: accepted, list: list,
            preview: { [weak self] selectors in self?.setPreview(selectors) },
            onClose: { [weak self] choice in self?.dialogDidClose(with: choice) })
        dialog = controller
        presentDialog(controller, pickWebView?.window)
    }

    /// A preview pick as the dialog takes it: This item is the selector the
    /// agent page recorded for the pick's ref (the live page's, never one
    /// computed against the preview's markup), All items like it is not
    /// offered (no looser selector is recorded), and the label is the
    /// node's. `nil` — refused — for no ref, a ref the page has no node for,
    /// a node with no selector or one for the page's root (`body`), and
    /// the document itself: the blank space
    /// between nodes carries the root's ref, and hiding it would hide the
    /// whole page from the agent.
    static func mapPreviewPick(_ candidate: BrowserPickCandidate, in page: AgentPage?) -> BrowserPickCandidate? {
        guard let ref = candidate.ref, let page, let node = page.node(ref: ref), !node.selector.isEmpty,
              !BrowserPickCandidate.isPageRoot(node.selector),
              !(node.kind == .document && node.ref == page.root?.ref) else { return nil }
        return BrowserPickCandidate(
            kind: .pick, thisItem: node.selector, allLikeIt: nil, allLikeItCount: 0,
            pageElementCount: candidate.pageElementCount, label: label(of: node), ref: ref)
    }

    /// The node's kind and up to 60 characters of its (already concealed)
    /// text, in the picker's `tag "text"` form.
    static func label(of node: AgentNode) -> String {
        let text = AgentPageText.collapse(AgentPageText.allText(node))
        guard !text.isEmpty else { return node.kind.rawValue }
        return node.kind.rawValue + " \"" + String(text.prefix(60)) + "\""
    }

    /// OK (with its choice) or Cancel (nil): save on OK, then resume.
    private func dialogDidClose(with choice: BrowserPickDialogController.Choice?) {
        guard case .dialog(let candidate) = state else { return }
        dialog = nil
        setPreview(nil)
        if let choice { save(choice, label: candidate.label) }
        pickRef = nil
        state = .selecting
        picker?.resume()
    }

    private func save(_ choice: BrowserPickDialogController.Choice, label: String) {
        // Fails closed: a pick whose address has no host is never saved as
        // an entry for every site.
        guard Self.canSelect(on: pickURL) else {
            Self.logger.error("hidden item not saved: the page has no site")
            NSSound.beep()
            return
        }
        let item = BrowserHiddenItem(
            list: list, site: PrivacySitePattern.defaultPattern(for: pickURL),
            selector: choice.selector, scope: choice.scope, label: label)
        let store = store
        lastSave = Task {
            do {
                _ = try await store.perform { try $0.add(item) }
            } catch {
                Self.logger.error("hidden item could not be saved: \(error.localizedDescription, privacy: .public)")
                NSSound.beep()
            }
        }
    }

    /// The dialog's "Show page with selected element removed". On the live
    /// page it is the engine's preview rule set; in the Agent preview the
    /// recorded selector names the live page's element, so the preview's own
    /// node is hidden by its ref instead, from the picker's world.
    private func setPreview(_ selectors: [String]?) {
        previewSelectors = selectors
        switch view {
        case .website:
            engine?.setPreviewHiddenSelectors(selectors)
        case .agentPreview:
            let hidden = selectors == nil ? [] : pickRef.map { [Self.refSelector($0)] } ?? []
            let script = BrowserHiddenItemsStyle.previewScript(selectors: hidden) + "\n;true"
            pickWebView?.evaluateJavaScript(script, in: nil, in: BrowserElementPicker.world) { result in
                if case .failure(let error) = result {
                    Self.logger.error("preview hide failed: \(error.localizedDescription, privacy: .public)")
                }
            }
        }
    }

    /// The CSS selector for the element carrying `ref` in the preview's markup.
    static func refSelector(_ ref: String) -> String {
        let escaped = ref.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        return "[data-adk-ref=\"\(escaped)\"]"
    }

    // MARK: - Esc

    private func installKeyMonitor() {
        removeKeyMonitor()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            // Only the Bool crosses back out: NSEvent is not `Sendable`.
            let consumed = MainActor.assumeIsolated { self.handleKeyDown(event) }
            return consumed ? nil : event
        }
    }

    private func removeKeyMonitor() {
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        keyMonitor = nil
    }

    /// Esc in the pane's window while selecting ends the mode and is
    /// swallowed; every other key goes on. With the dialog up, Esc is the
    /// dialog's Cancel. Returns whether the key was consumed.
    func handleKeyDown(_ event: NSEvent) -> Bool {
        guard state == .selecting, event.keyCode == 53,
              event.window === pickWebView?.window else { return false }
        end(.escape)
        return true
    }

    // MARK: - First-use notice

    private func showNoticeIfFirstUse(in window: NSWindow?) {
        guard !settings.get(UserSettings.browserHiddenItemsNoticeShown) else { return }
        settings.set(true, for: UserSettings.browserHiddenItemsNoticeShown)
        presentNotice(window)
    }

    // MARK: - Default presenters

    /// App-modal through `AppModalWindowSession`, which enters the modal
    /// loop on the run loop's next pass rather than from a main-queue block,
    /// so every MainActor task in the app keeps running while it is up.
    private static func runModalDialog(_ dialog: BrowserPickDialogController, parent: NSWindow?) {
        dialog.present(over: parent)
    }

    /// An informational alert, as a sheet on the pane's window so nothing
    /// else in the app is held up by it. A pane in no window has had no
    /// click to start selecting from, and gets none.
    private static func showNotice(in window: NSWindow?) {
        guard let window else { return }
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = noticeText
        alert.addButton(withTitle: "OK")
        alert.beginSheetModal(for: window)
    }

    /// The page's host and the view, for the log: never a selector or a label.
    private var logPlace: String {
        "\(engine?.url?.host ?? "no address") (\(view.rawValue))"
    }
}
