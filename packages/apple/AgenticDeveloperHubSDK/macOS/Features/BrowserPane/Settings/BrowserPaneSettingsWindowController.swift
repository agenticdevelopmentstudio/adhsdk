//
//  BrowserPaneSettingsWindowController.swift
//  AgenticDeveloperHubSDK
//

import AgenticDeveloperHubSDKCoreUI
import AppKit

/// A browser pane's settings in an ordinary window, movable, resizable and
/// titled like every other window, run app-modal so only one is ever open.
/// Closing the window ends the settings (and the modal session), which is
/// when the pane rebuilds for a construction-time change. The settings sit in
/// a plain container, so neither a topic's content nor a preferred content
/// size ever resizes the window: the window sizes the settings.
@MainActor
final class BrowserPaneSettingsWindowController: SingleWindowController {

    private static var open: [ObjectIdentifier: BrowserPaneSettingsWindowController] = [:]
    private let key: ObjectIdentifier
    let settings: BrowserPaneSettingsSheetController

    /// Brings `pane`'s settings window forward, or opens one with `make`.
    static func show(for pane: WebBrowserPaneViewController,
                     make: () -> BrowserPaneSettingsSheetController?) {
        let key = ObjectIdentifier(pane)
        if let existing = open[key] {
            existing.showWindow()
            return
        }
        guard let settings = make() else { return }
        let controller = BrowserPaneSettingsWindowController(settings: settings, key: key)
        open[key] = controller
        controller.showWindow()
        controller.startModal()
    }

    /// Closes `pane`'s settings window, if one is open: the pane is being
    /// discarded, and settings bound to it would otherwise outlive it — still
    /// app-modal, and holding the pane, its torn-down web views and its jar's
    /// data store until someone closed them.
    static func close(for pane: WebBrowserPaneViewController) {
        open[ObjectIdentifier(pane)]?.window?.close()
    }

    /// Whether `NSApp.runModal(for:)` is running this window.
    private var isRunningModal = false
    private var isClosed = false

    /// Runs the window app-modal, on the next pass of the run loop — so the
    /// menu that asked has finished tracking — and from a run loop block,
    /// never a main-queue one. A modal loop entered inside a main-queue block
    /// holds the main queue for as long as the window is up, so nothing on
    /// the main actor runs meanwhile: no `Task` a button starts, no `await`
    /// resuming (Edit Privacy Words did nothing for exactly that reason).
    private func startModal() {
        CFRunLoopPerformBlock(CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue) { [weak self] in
            MainActor.assumeIsolated {
                guard let self, !self.isClosed, !self.isRunningModal,
                      let window = self.window, window.isVisible else { return }
                self.isRunningModal = true
                NSApp.runModal(for: window)
                self.isRunningModal = false
            }
        }
        CFRunLoopWakeUp(CFRunLoopGetMain())
    }

    /// Ends the modal loop now. `stopModal` takes effect when the loop next
    /// handles an event, so one is posted for a stop that came from none.
    private func stopModal() {
        guard isRunningModal, NSApp.modalWindow === window else { return }
        NSApp.stopModal()
        if let wake = NSEvent.otherEvent(with: .applicationDefined, location: .zero, modifierFlags: [],
                                         timestamp: 0, windowNumber: 0, context: nil,
                                         subtype: 0, data1: 0, data2: 0) {
            NSApp.postEvent(wake, atStart: true)
        }
    }

    /// Ends the app-modal session on `window`, when it is a pane settings
    /// window running one, and returns what starts it again; nil otherwise.
    ///
    /// For the system's authentication prompt: while a window is app-modal
    /// only that window can be key or take clicks, so the prompt opens behind
    /// it and cannot be answered. The settings stay open meanwhile; the
    /// caller resumes the session once the prompt is answered.
    static func suspendModal(of window: NSWindow?) -> (() -> Void)? {
        guard let window, let controller = open.values.first(where: { $0.window === window }),
              controller.isRunningModal else { return nil }
        controller.stopModal()
        return { [weak controller] in controller?.startModal() }
    }

    private init(settings: BrowserPaneSettingsSheetController, key: ObjectIdentifier) {
        self.key = key
        self.settings = settings
        settings.presentsInWindow = true
        let container = NSViewController()
        container.view = NSView(frame: NSRect(x: 0, y: 0, width: 820, height: 560))
        container.addChild(settings)
        let settingsView = settings.view
        settingsView.translatesAutoresizingMaskIntoConstraints = true
        settingsView.autoresizingMask = [.width, .height]
        settingsView.frame = container.view.bounds
        container.view.addSubview(settingsView)
        super.init(windowID: "browser-pane-settings-\(UUID().uuidString)", contentViewController: container)
        windowTitle = settings.title ?? "Browser Settings"
        // Not minimisable: the window is app-modal, so in the Dock it would
        // leave every other window refusing input with nothing on screen to
        // answer — the yellow button, Window > Minimize and a title-bar
        // double-click all go through this mask.
        windowStyleMask = [.titled, .closable, .resizable]
        windowSpec = WindowSpec(
            defaultSize: NSSize(width: 820, height: 560),
            minSize: NSSize(width: 560, height: 360),
            defaultPosition: .center,
            persistsFrame: false,
            behavior: []
        )
        accessibilityIdentifier = "browser.pane-settings.window"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func windowWillClose(_ notification: Notification) {
        super.windowWillClose(notification)
        Self.open[key] = nil
        stopModal()
        isClosed = true
        settings.finish(dismissing: false)
    }
}
