//
//  BrowserPaneSettingsWindowController.swift
//  AgenticDeveloperHubSDK
//

import AgenticDeveloperHubSDKCoreUI
import AppKit

/// A browser pane's settings in an ordinary window, movable, resizable and
/// titled like every other window, rather than a sheet over the pane. One per
/// pane: Settings… again brings it forward. Closing the window ends the
/// settings, which is when the pane rebuilds for a construction-time change.
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
    }

    private init(settings: BrowserPaneSettingsSheetController, key: ObjectIdentifier) {
        self.key = key
        self.settings = settings
        settings.presentsInWindow = true
        super.init(windowID: "browser-pane-settings-\(UUID().uuidString)", contentViewController: settings)
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
        settings.finish(dismissing: false)
    }
}
