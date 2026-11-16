//
//  BrowserPrivacySettingsDialog.swift
//  AgenticDeveloperHubSDK
//

import AppKit

/// One browser pane's Privacy and Security topic alone, in a popover whose arrow points at
/// the privacy button: the same `BrowserPrivacySettingsPanel` the full
/// settings show, bound in pane scope, so it reads the global values until
/// the pane overrides one and writes only the pane's layer (`dry`).
///
/// It opens and closes the way the full settings window does
/// (`BrowserPaneSettingsWindowController`): the pane's
/// `makePaneSettingsController()` records the construction-time values when
/// it opens, and the popover's closing finishes that controller, which
/// rebuilds the pane if one of them changed. Edit Privacy Words… closes the popover and
/// opens its editor over the pane's window, since a popover is no window to
/// put a sheet on. One per pane.
@MainActor
final class BrowserPrivacySettingsDialog: NSObject, NSPopoverDelegate {

    private static var open: [ObjectIdentifier: BrowserPrivacySettingsDialog] = [:]
    private let key: ObjectIdentifier
    /// Owns the open/close semantics; its own view is never shown.
    private let session: BrowserPaneSettingsViewController
    private let popover = NSPopover()

    /// Shows `pane`'s Privacy and Security settings in a popover from `button`, or closes
    /// the one already showing. Does nothing for a pane with no settings
    /// layer of its own.
    static func present(for pane: WebBrowserPaneViewController, from button: NSView) {
        let key = ObjectIdentifier(pane)
        if let existing = open[key] {
            existing.popover.performClose(nil)
            return
        }
        guard let layered = pane.paneSettings, let session = pane.makePaneSettingsController() else { return }
        let binding = BrowserSettingsBinding(settings: layered.fallback, scope: .pane(layered, pane))
        let dialog = BrowserPrivacySettingsDialog(session: session, key: key)
        // Resolved when Manage Site Data… is pressed, so it is the jar the
        // popover's Storage names then; `nil` (a Chrome pane) has no group.
        let siteData: (() -> BrowserSiteData?)? = pane is SafariBrowserPaneViewController
            ? { [weak pane] in
                pane.flatMap { BrowserSettingsPanelViewController.siteData(for: $0, under: layered) }
            }
            : nil
        let panel = BrowserPrivacySettingsPanel(
            binding: binding,
            siteData: siteData
        ) { [weak pane, weak dialog] in
            dialog?.popover.performClose(nil)
            return pane?.view.window
        }
        let container = NSViewController()
        container.view = NSView(frame: NSRect(x: 0, y: 0, width: 520, height: 660))
        let title = NSTextField(labelWithString: "Privacy and Security")
        title.font = .boldSystemFont(ofSize: NSFont.systemFontSize + 2)
        title.setAccessibilityIdentifier("browser.privacy-settings.title")
        title.translatesAutoresizingMaskIntoConstraints = false
        container.view.addSubview(title)
        container.addChild(panel)
        let panelView = panel.view
        panelView.translatesAutoresizingMaskIntoConstraints = false
        container.view.addSubview(panelView)
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: container.view.topAnchor, constant: 14),
            title.centerXAnchor.constraint(equalTo: container.view.centerXAnchor),
            panelView.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 6),
            panelView.leadingAnchor.constraint(equalTo: container.view.leadingAnchor),
            panelView.trailingAnchor.constraint(equalTo: container.view.trailingAnchor),
            panelView.bottomAnchor.constraint(equalTo: container.view.bottomAnchor)
        ])
        container.view.setAccessibilityIdentifier("browser.privacy-settings.popover")
        dialog.popover.contentViewController = container
        dialog.popover.contentSize = container.view.frame.size
        open[key] = dialog
        dialog.popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    private init(session: BrowserPaneSettingsViewController, key: ObjectIdentifier) {
        self.session = session
        self.key = key
        super.init()
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
    }

    func popoverDidClose(_ notification: Notification) {
        Self.open[key] = nil
        session.finish()
    }
}
