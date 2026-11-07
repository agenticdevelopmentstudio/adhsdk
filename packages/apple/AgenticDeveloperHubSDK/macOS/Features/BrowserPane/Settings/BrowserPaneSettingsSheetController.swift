//
//  BrowserPaneSettingsSheetController.swift
//  AgenticDeveloperHubSDK
//

import AppKit

import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreUI
import AgenticDeveloperHubSDKCoreMacOS

/// One browser pane's settings, as a sheet on the pane's window (spec
/// section 3): the Browser panel in pane scope, over the pane's own settings
/// layer, with a Done button.
///
/// The same shape as the project settings sheet
/// (`ComposableTabsSettingsViewController`) — a topic list, a panel, help in a
/// popover, Done — because it is the same kind of thing, and the panel inside
/// is the Settings window's own Browser panel bound to a different store, not
/// a second copy of it (`dry`). Every change is written as it is made; the
/// ones WebKit fixes at construction are applied by the pane when the sheet
/// closes, which is what `onClose` is for.
@MainActor
public final class BrowserPaneSettingsSheetController: NSViewController {

    /// Called once, when the sheet has gone. The pane rebuilds its web view
    /// here if a construction-time setting changed.
    public var onClose: (() -> Void)?

    /// The Browser panel in pane scope. Internal so a test can reach its rows.
    let panels: BrowserSettingsPanelViewController
    /// A sheet has no free edge for a drawer, so help opens in a popover off
    /// the help button. Held here: the panel holds its presenter weakly.
    private let help = ComposableSettings.HelpPopoverController()
    private let paneTitle: String
    private var hasClosed = false

    /// `nil` when the pane has no settings layer of its own — a pane built
    /// over the shared store directly, whose every change would be global.
    public init?(pane: BrowserPaneViewController, history: BrowserHistoryStore?) {
        guard let layered = pane.paneSettings else { return nil }
        self.paneTitle = pane.paneTitle
        self.panels = BrowserSettingsPanelViewController(
            history: history,
            settings: layered.fallback,
            scope: .pane(layered, pane)
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

    public override func loadView() {
        let container = ThemedBackgroundView(role: .windowBackground)
        container.accessibilityID("browser.pane-settings")

        // A sheet has no title bar, so its title is the first thing in it.
        let heading = NSTextField(labelWithString: Self.title(for: paneTitle))
        heading.font = .boldSystemFont(ofSize: NSFont.systemFontSize)
        heading.lineBreakMode = .byTruncatingMiddle
        heading.translatesAutoresizingMaskIntoConstraints = false
        heading.accessibilityID("browser.pane-settings.title")
        container.addSubview(heading)

        addChild(panels)
        panels.helpPresenter = help
        let panelsView = panels.view
        panelsView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(panelsView)
        panels.selectPanel(at: 0)

        let done = NSButton(title: "Done", target: self, action: #selector(close(_:)))
        done.bezelStyle = .rounded
        done.keyEquivalent = "\r"
        done.translatesAutoresizingMaskIntoConstraints = false
        done.accessibilityID("browser.pane-settings.done")
        container.addSubview(done)

        NSLayoutConstraint.activate([
            heading.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            heading.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            container.trailingAnchor.constraint(greaterThanOrEqualTo: heading.trailingAnchor, constant: 20),

            panelsView.topAnchor.constraint(equalTo: heading.bottomAnchor, constant: 10),
            panelsView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: panelsView.trailingAnchor),

            done.topAnchor.constraint(equalTo: panelsView.bottomAnchor, constant: 12),
            container.trailingAnchor.constraint(equalTo: done.trailingAnchor, constant: 20),
            container.bottomAnchor.constraint(equalTo: done.bottomAnchor, constant: 16)
        ])

        self.view = container
        self.preferredContentSize = NSSize(width: 820, height: 560)
    }

    public override func viewDidDisappear() {
        super.viewDidDisappear()
        guard !hasClosed else { return }
        hasClosed = true
        onClose?()
    }

    @objc private func close(_ sender: Any?) {
        dismiss(self)
    }
}
