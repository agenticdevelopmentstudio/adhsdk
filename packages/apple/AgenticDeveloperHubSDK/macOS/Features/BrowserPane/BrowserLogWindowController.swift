//
//  BrowserLogWindowController.swift
//  AgenticDeveloperHubSDK
//

import AgenticDeveloperHubSDKCoreUI
import AppKit

/// The browser log in a window of its own, for a browser that is in no
/// project window (a web browser window) and so has no layout to open the
/// log pane beside. One per browser: asking again brings it forward.
@MainActor
final class BrowserLogWindowController: SingleWindowController {

    private static var open: [ObjectIdentifier: BrowserLogWindowController] = [:]
    private let key: ObjectIdentifier
    private let log: BrowserLogPaneViewController

    static func show(for pane: WebBrowserPaneViewController) {
        let key = ObjectIdentifier(pane)
        let controller = open[key] ?? BrowserLogWindowController(pane: pane, key: key)
        open[key] = controller
        controller.showWindow()
    }

    private init(pane: WebBrowserPaneViewController, key: ObjectIdentifier) {
        self.key = key
        self.log = BrowserLogPaneViewController(following: pane)
        super.init(windowID: "browser-log-\(UUID().uuidString)", contentViewController: log)
        windowTitle = "Browser Log: \(pane.paneTitle)"
        windowStyleMask = [.titled, .closable, .resizable, .miniaturizable]
        windowSpec = WindowSpec(
            defaultSize: NSSize(width: 720, height: 420),
            minSize: NSSize(width: 420, height: 240),
            defaultPosition: .center,
            persistsFrame: false,
            behavior: []
        )
        accessibilityIdentifier = "browser-log.window"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func windowWillClose(_ notification: Notification) {
        super.windowWillClose(notification)
        Self.open[key] = nil
        // Unique to this opening, so nothing will ask for it again.
        WindowManager.shared.forgetOneOffWindow(self)
    }
}
