//
//  BrowserPrivacySettingsDialog.swift
//  AgenticDeveloperHubSDK
//

import AppKit

/// One browser pane's Privacy topic alone, in a popover whose arrow points at
/// the privacy button: the same `BrowserPrivacySettingsPanel` the full
/// settings show, bound in pane scope, so it reads the global values until
/// the pane overrides one and writes only the pane's layer (`dry`).
///
/// It opens and closes the way the full settings window does
/// (`BrowserPaneSettingsWindowController`): the pane's
/// `makePaneSettingsSheet()` records the construction-time values when it
/// opens, and the popover's closing finishes that sheet, which rebuilds the
/// pane if one of them changed. Edit Privacy Words… closes the popover and
/// opens its editor over the pane's window, since a popover is no window to
/// put a sheet on. One per pane.
@MainActor
final class BrowserPrivacySettingsDialog: NSObject, NSPopoverDelegate {

    private static var open: [ObjectIdentifier: BrowserPrivacySettingsDialog] = [:]
    private let key: ObjectIdentifier
    /// Owns the open/close semantics; its own view is never shown.
    private let session: BrowserPaneSettingsSheetController
    private let popover = NSPopover()

    /// Shows `pane`'s Privacy settings in a popover from `button`, or closes
    /// the one already showing. Does nothing for a pane with no settings
    /// layer of its own.
    static func present(for pane: WebBrowserPaneViewController, from button: NSView) {
        let key = ObjectIdentifier(pane)
        if let existing = open[key] {
            existing.popover.performClose(nil)
            return
        }
        guard let layered = pane.paneSettings, let session = pane.makePaneSettingsSheet() else { return }
        let binding = BrowserSettingsBinding(settings: layered.fallback, scope: .pane(layered, pane))
        let dialog = BrowserPrivacySettingsDialog(session: session, key: key)
        let panel = BrowserPrivacySettingsPanel(binding: binding) { [weak pane, weak dialog] in
            dialog?.popover.performClose(nil)
            return pane?.view.window
        }
        let container = NSViewController()
        container.view = NSView(frame: NSRect(x: 0, y: 0, width: 520, height: 560))
        container.addChild(panel)
        let panelView = panel.view
        panelView.translatesAutoresizingMaskIntoConstraints = true
        panelView.autoresizingMask = [.width, .height]
        panelView.frame = container.view.bounds
        container.view.addSubview(panelView)
        container.view.setAccessibilityIdentifier("browser.privacy-settings.popover")
        dialog.popover.contentViewController = container
        dialog.popover.contentSize = container.view.frame.size
        open[key] = dialog
        dialog.popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    private init(session: BrowserPaneSettingsSheetController, key: ObjectIdentifier) {
        self.session = session
        self.key = key
        super.init()
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
    }

    func popoverDidClose(_ notification: Notification) {
        Self.open[key] = nil
        session.finish(dismissing: false)
    }
}
