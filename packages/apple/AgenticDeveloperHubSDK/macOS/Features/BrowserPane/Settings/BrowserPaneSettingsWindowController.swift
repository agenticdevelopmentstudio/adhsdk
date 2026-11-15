//
//  BrowserPaneSettingsWindowController.swift
//  AgenticDeveloperHubSDK
//

import AgenticDeveloperHubSDKCoreMacOS
import AgenticDeveloperHubSDKCoreUI
import AppKit

/// A browser pane's settings in an ordinary window, movable, resizable and
/// titled like every other window, run app-modal so only one is ever open
/// (`AppModalWindowSession`, which also steps aside for the system's
/// authentication prompt). Closing the window ends the settings (and the
/// modal session), which is when the pane rebuilds for a construction-time
/// change. The settings sit in a plain container, so neither a topic's content
/// nor a preferred content size ever resizes the window: the window sizes the
/// settings.
@MainActor
final class BrowserPaneSettingsWindowController: SingleWindowController {

    private static var open: [ObjectIdentifier: BrowserPaneSettingsWindowController] = [:]
    private let key: ObjectIdentifier
    let settings: BrowserPaneSettingsViewController

    /// Brings `pane`'s settings window forward, or opens one with `make`.
    static func show(for pane: WebBrowserPaneViewController,
                     make: () -> BrowserPaneSettingsViewController?) {
        let key = ObjectIdentifier(pane)
        if let existing = open[key] {
            existing.showWindow()
            return
        }
        guard let settings = make() else { return }
        let controller = BrowserPaneSettingsWindowController(settings: settings, key: key)
        open[key] = controller
        controller.showWindow()
        if let window = controller.window {
            let session = AppModalWindowSession(window: window)
            controller.modalSession = session
            session.start()
        }
    }

    /// Closes `pane`'s settings window, if one is open: the pane is being
    /// discarded, and settings bound to it would otherwise outlive it — still
    /// app-modal, and holding the pane, its torn-down web views and its jar's
    /// data store until someone closed them.
    static func close(for pane: WebBrowserPaneViewController) {
        open[ObjectIdentifier(pane)]?.window?.close()
    }

    /// The app-modal session, from `show` until the window closes.
    private var modalSession: AppModalWindowSession?

    private init(settings: BrowserPaneSettingsViewController, key: ObjectIdentifier) {
        self.key = key
        self.settings = settings
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
        modalSession?.end()
        modalSession = nil
        settings.finish()
        // Unique to this opening, so nothing will ask for it again.
        WindowManager.shared.forgetOneOffWindow(self)
    }
}
