//
//  BrowserSelectingMode.swift
//  AgenticDeveloperHubSDK
//

import AgenticDeveloperHubSDKCore
import AppKit
import OSLog

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
@MainActor
final class BrowserSelectingMode {

    enum State: Equatable {
        case idle
        case selecting
        case dialog(BrowserPickCandidate)
    }

    /// Why selecting ended, for the log.
    enum EndReason: String {
        case stop
        case escape = "Esc"
        case navigation
        case tabSwitch = "tab switch"
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
    private(set) weak var engine: WebKitBrowserEngine?
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
    /// The preview rule set last asked for; nil when there is none.
    private(set) var previewSelectors: [String]?
    /// The last save started, so a test can wait for it.
    private(set) var lastSave: Task<Void, Never>?
    private static let logger = Logger(subsystem: "AgenticDeveloperHubSDK", category: "BrowserPane")

    init(engine: WebKitBrowserEngine, store: BrowserHiddenItemsStore, list: BrowserHiddenItemList,
         button: BrowserHideItemsButton, settings: SettingsStore = UserSettings.shared,
         presentDialog: DialogPresenter? = nil, presentNotice: NoticePresenter? = nil) {
        self.engine = engine
        self.store = store
        self.list = list
        self.button = button
        self.settings = (settings as? LayeredSettingsStore)?.fallback ?? settings
        self.presentDialog = presentDialog ?? Self.runModalDialog
        self.presentNotice = presentNotice ?? Self.showNotice
    }

    var isActive: Bool { state != .idle }

    // MARK: - Starting and ending

    /// Starts selecting on the engine's page. Starting while selecting (or
    /// with the dialog up) does nothing, so a pane never has two pickers.
    func begin() {
        guard state == .idle, let engine else { return }
        state = .selecting
        button.showSelecting(true)
        showNoticeIfFirstUse(in: engine.webView.window)
        installKeyMonitor()
        let picker = BrowserElementPicker(
            webView: engine.webView, list: list,
            onPick: { [weak self] candidate in self?.handlePick(candidate) },
            onCancel: { [weak self] in self?.end(.escape) })
        self.picker = picker
        Self.logger.info("selecting mode started on \(Self.host(engine.url), privacy: .public)")
        // After the previous start, so two pickers never install at once in
        // the one content world they share.
        let previous = startTask
        startTask = Task { [weak self] in
            await previous?.value
            // Ended before the start could run: install nothing.
            guard let self, self.picker === picker else { return }
            do {
                try await picker.start()
            } catch {
                if self.picker === picker { self.end(.failure) }
                return
            }
            // Ended while the start was in flight: take the stray picker down.
            if self.picker !== picker { picker.stop() }
        }
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
        removeKeyMonitor()
        setPreview(nil)
        pickURL = nil
        button.showSelecting(false)
        let host = Self.host(engine?.url)
        Self.logger.info(
            "selecting mode ended (\(reason.rawValue, privacy: .public)) on \(host, privacy: .public)")
    }

    // MARK: - Picks and the dialog

    /// An accepted pick: pause the picker and open the dialog for it.
    func handlePick(_ candidate: BrowserPickCandidate) {
        guard state == .selecting, candidate.thisItem != nil else { return }
        picker?.pause()
        state = .dialog(candidate)
        pickURL = engine?.url
        let controller = BrowserPickDialogController(
            candidate: candidate, list: list,
            preview: { [weak self] selectors in self?.setPreview(selectors) },
            onClose: { [weak self] choice in self?.dialogDidClose(with: choice) })
        dialog = controller
        presentDialog(controller, engine?.webView.window)
    }

    /// OK (with its choice) or Cancel (nil): save on OK, then resume.
    private func dialogDidClose(with choice: BrowserPickDialogController.Choice?) {
        guard case .dialog(let candidate) = state else { return }
        dialog = nil
        setPreview(nil)
        if let choice { save(choice, label: candidate.label) }
        state = .selecting
        picker?.resume()
    }

    private func save(_ choice: BrowserPickDialogController.Choice, label: String) {
        let item = BrowserHiddenItem(
            list: list, site: PrivacySitePattern.defaultPattern(for: pickURL),
            selector: choice.selector, scope: choice.scope, label: label)
        let store = store
        lastSave = Task {
            do {
                _ = try await store.perform { try $0.add(item) }
            } catch {
                Self.logger.error("hidden item could not be saved: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func setPreview(_ selectors: [String]?) {
        previewSelectors = selectors
        engine?.setPreviewHiddenSelectors(selectors)
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
              event.window === engine?.webView.window else { return false }
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

    /// On the run loop's next pass, not as a main-queue block: a modal loop
    /// started from `DispatchQueue.main.async` would hold the main queue, and
    /// with it every MainActor task in the app, until the dialog closed.
    private static func runModalDialog(_ dialog: BrowserPickDialogController, parent: NSWindow?) {
        performOnNextRunLoopPass { dialog.runModal(over: parent) }
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

    private static func host(_ url: URL?) -> String {
        url?.host ?? "no address"
    }
}
