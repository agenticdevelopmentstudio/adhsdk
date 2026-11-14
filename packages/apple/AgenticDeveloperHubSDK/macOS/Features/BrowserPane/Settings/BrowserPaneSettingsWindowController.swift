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
        // Next pass, so the menu that asked has finished tracking.
        DispatchQueue.main.async { [weak controller] in
            guard let window = controller?.window, window.isVisible else { return }
            NSApp.runModal(for: window)
        }
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
        windowStyleMask = [.titled, .closable, .resizable, .miniaturizable]
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
        if NSApp.modalWindow === window { NSApp.stopModal() }
        settings.finish(dismissing: false)
    }
}
