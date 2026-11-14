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
        container.view = NSView(frame: NSRect(x: 0, y: 0, width: 520, height: 660))
        let title = NSTextField(labelWithString: "Privacy")
        title.font = .boldSystemFont(ofSize: NSFont.systemFontSize + 2)
        title.setAccessibilityIdentifier("browser.privacy-settings.title")
        title.translatesAutoresizingMaskIntoConstraints = false
        container.view.addSubview(title)
        let pause = NSButton(checkboxWithTitle: "Pause all events", target: dialog,
                             action: #selector(togglePause(_:)))
        pause.state = pane.isEventsPaused ? .on : .off
        pause.setAccessibilityIdentifier("browser.privacy-settings.pause")
        let strip = NSButton(checkboxWithTitle: "Show Privacy Settings toolbar", target: dialog,
                             action: #selector(toggleStrip(_:)))
        strip.state = pane.isPrivacyStripShown ? .on : .off
        strip.setAccessibilityIdentifier("browser.privacy-settings.show-strip")
        let toggles = NSStackView(views: [pause, strip])
        toggles.orientation = .vertical
        toggles.alignment = .leading
        toggles.spacing = 6
        toggles.translatesAutoresizingMaskIntoConstraints = false
        container.view.addSubview(toggles)
        dialog.pane = pane
        container.addChild(panel)
        let panelView = panel.view
        panelView.translatesAutoresizingMaskIntoConstraints = false
        container.view.addSubview(panelView)
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: container.view.topAnchor, constant: 14),
            title.centerXAnchor.constraint(equalTo: container.view.centerXAnchor),
            toggles.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 10),
            toggles.leadingAnchor.constraint(equalTo: container.view.leadingAnchor, constant: 20),
            panelView.topAnchor.constraint(equalTo: toggles.bottomAnchor, constant: 6),
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

    private init(session: BrowserPaneSettingsSheetController, key: ObjectIdentifier) {
        self.session = session
        self.key = key
        super.init()
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
    }

    private weak var pane: WebBrowserPaneViewController?

    @objc private func togglePause(_ sender: NSButton) {
        pane?.setEventsPaused(sender.state == .on)
    }

    @objc private func toggleStrip(_ sender: NSButton) {
        pane?.isPrivacyStripShown = sender.state == .on
    }

    func popoverDidClose(_ notification: Notification) {
        Self.open[key] = nil
        session.finish(dismissing: false)
    }
}
