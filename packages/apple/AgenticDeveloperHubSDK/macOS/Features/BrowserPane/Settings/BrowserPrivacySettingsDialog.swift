//
//  BrowserPrivacySettingsDialog.swift
//  AgenticDeveloperHubSDK
//

import AgenticDeveloperHubSDKCoreUI
import AppKit

/// One browser pane's Privacy topic alone, in an app-modal window: the same
/// `BrowserPrivacySettingsPanel` the full settings show, bound in pane scope,
/// so it reads the global values until the pane overrides one and writes
/// only the pane's layer (`dry`).
///
/// It opens and closes the way the full settings window does
/// (`BrowserPaneSettingsWindowController`): the pane's
/// `makePaneSettingsSheet()` records the construction-time values when it
/// opens, and closing the window finishes that sheet, which rebuilds the pane
/// if one of them changed. Movable, resizable and closable; one per pane.
@MainActor
final class BrowserPrivacySettingsDialog: SingleWindowController {

    private static var open: [ObjectIdentifier: BrowserPrivacySettingsDialog] = [:]
    private let key: ObjectIdentifier
    /// Owns the open/close semantics; its own view is never shown.
    private let session: BrowserPaneSettingsSheetController
    let panel: BrowserPrivacySettingsPanel

    /// Shows `pane`'s Privacy settings, app-modal, or brings forward the
    /// dialog already open for it. Does nothing for a pane with no settings
    /// layer of its own.
    static func present(for pane: WebBrowserPaneViewController) {
        let key = ObjectIdentifier(pane)
        if let existing = open[key] {
            existing.showWindow()
            return
        }
        guard let layered = pane.paneSettings, let session = pane.makePaneSettingsSheet() else { return }
        let binding = BrowserSettingsBinding(settings: layered.fallback, scope: .pane(layered, pane))
        let dialog = BrowserPrivacySettingsDialog(
            panel: BrowserPrivacySettingsPanel(binding: binding),
            session: session,
            title: "Privacy for \(pane.paneTitle)",
            key: key
        )
        open[key] = dialog
        dialog.showWindow()
        // Next pass, so the control that asked has finished tracking.
        DispatchQueue.main.async { [weak dialog] in
            guard let window = dialog?.window, window.isVisible else { return }
            NSApp.runModal(for: window)
        }
    }

    private init(
        panel: BrowserPrivacySettingsPanel,
        session: BrowserPaneSettingsSheetController,
        title: String,
        key: ObjectIdentifier
    ) {
        self.panel = panel
        self.session = session
        self.key = key
        let container = NSViewController()
        container.view = NSView(frame: NSRect(x: 0, y: 0, width: 620, height: 560))
        container.addChild(panel)
        let panelView = panel.view
        panelView.translatesAutoresizingMaskIntoConstraints = true
        panelView.autoresizingMask = [.width, .height]
        panelView.frame = container.view.bounds
        container.view.addSubview(panelView)
        super.init(windowID: "browser-privacy-settings-\(UUID().uuidString)", contentViewController: container)
        windowTitle = title
        windowStyleMask = [.titled, .closable, .resizable]
        windowSpec = WindowSpec(
            defaultSize: NSSize(width: 620, height: 560),
            minSize: NSSize(width: 420, height: 320),
            defaultPosition: .center,
            persistsFrame: false,
            behavior: []
        )
        accessibilityIdentifier = "browser.privacy-settings.window"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func windowWillClose(_ notification: Notification) {
        super.windowWillClose(notification)
        Self.open[key] = nil
        if NSApp.modalWindow === window { NSApp.stopModal() }
        session.finish(dismissing: false)
    }
}
