//
//  BrowserPaneSettingsViewController.swift
//  AgenticDeveloperHubSDK
//

import AppKit

import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreUI
import AgenticDeveloperHubSDKCoreMacOS
import AgenticDeveloperHubSDKDatabase

/// One browser pane's settings (spec section 3): the Browser panel in pane
/// scope, over the pane's own settings layer, with an OK button. Shown in a
/// window of its own (`BrowserPaneSettingsWindowController`), whose title bar
/// carries the title and whose close button ends it; the Privacy popover
/// (`BrowserPrivacySettingsDialog`) uses one only for its open and close.
///
/// The panel inside is the Settings window's own Browser panel bound to a
/// different store, not a second copy of it (`dry`). Every change is written
/// as it is made; the ones WebKit fixes at construction are applied by the
/// pane when the settings close, which is what `onClose` is for.
@MainActor
public final class BrowserPaneSettingsViewController: NSViewController {

    /// Called once, when the settings have gone. The pane rebuilds its web
    /// view here if a construction-time setting changed.
    public var onClose: (() -> Void)?

    /// The Browser panel in pane scope. Internal so a test can reach its rows.
    let panels: BrowserSettingsPanelViewController
    /// Help opens in a popover off the help button. Held here: the panel
    /// holds its presenter weakly.
    private let help = ComposableSettings.HelpPopoverController()
    private let paneTitle: String
    private var hasClosed = false

    /// `nil` when the pane has no settings layer of its own — a pane built
    /// over the shared store directly, whose every change would be global.
    public init?(pane: WebBrowserPaneViewController, history: (any BrowserHistoryStoring)?) {
        guard let layered = pane.paneSettings else { return nil }
        self.paneTitle = pane.paneTitle
        self.panels = BrowserSettingsPanelViewController(
            history: history,
            settings: layered.fallback,
            scope: .pane(layered, pane),
            chrome: pane.engineMaintenance
        )
        super.init(nibName: nil, bundle: nil)
        self.title = Self.title(for: paneTitle)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// "Settings for <pane title>".
    static func title(for paneTitle: String) -> String {
        "Settings for \(paneTitle)"
    }

    static let okIdentifier = "browser.pane-settings.ok"

    /// The panel, and OK — the default button — under it. OK closes the
    /// window exactly as the close button does.
    public override func loadView() {
        let container = ThemedBackgroundView(role: .windowBackground)
        container.accessibilityID("browser.pane-settings")

        addChild(panels)
        panels.helpPresenter = help
        let panelsView = panels.view
        panelsView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(panelsView)
        panels.selectPanel(at: 0)

        let okButton = NSButton(title: "OK", target: self, action: #selector(closeWindow(_:)))
        okButton.bezelStyle = .rounded
        okButton.keyEquivalent = "\r"
        okButton.translatesAutoresizingMaskIntoConstraints = false
        okButton.accessibilityID(Self.okIdentifier)
        container.addSubview(okButton)

        NSLayoutConstraint.activate([
            panelsView.topAnchor.constraint(equalTo: container.topAnchor),
            panelsView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: panelsView.trailingAnchor),

            okButton.topAnchor.constraint(equalTo: panelsView.bottomAnchor, constant: 12),
            okButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
            container.trailingAnchor.constraint(equalTo: okButton.trailingAnchor, constant: 20),
            container.bottomAnchor.constraint(equalTo: okButton.bottomAnchor, constant: 16)
        ])
        self.view = container
    }

    /// OK: the window's close, which ends the settings
    /// (`BrowserPaneSettingsWindowController.windowWillClose`).
    @objc private func closeWindow(_ sender: Any?) {
        view.window?.performClose(sender)
    }

    /// Ends the settings: calls `onClose` once, however many ways the end is
    /// reported. Internal so a test can close settings it never put on
    /// screen.
    func finish() {
        guard !hasClosed else { return }
        hasClosed = true
        onClose?()
    }
}
