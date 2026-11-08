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
    public init?(pane: WebBrowserPaneViewController, history: BrowserHistoryStore?) {
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

    /// Watches the window the sheet is on for the sheet ending, so a
    /// dismissal that does not come through Done — the presenter dismissing
    /// it, the window closing — still closes it.
    public override func viewDidAppear() {
        super.viewDidAppear()
        guard !hasClosed, parentWindow == nil, let parent = view.window?.sheetParent else { return }
        parentWindow = parent
        NotificationCenter.default.addObserver(
            self, selector: #selector(parentDidEndSheet(_:)),
            name: NSWindow.didEndSheetNotification, object: parent
        )
    }

    /// A disappearance is the sheet ending only once its window is no longer
    /// attached to a parent: the window being ordered out with its parent —
    /// miniaturized, its Space left — also sends `viewDidDisappear`, and that
    /// must not close the sheet (it would rebuild the pane under a sheet that
    /// is still open, then never close again).
    public override func viewDidDisappear() {
        super.viewDidDisappear()
        guard view.window?.sheetParent == nil else { return }
        finish(dismissing: false)
    }

    /// The window that had the sheet, while the sheet is on it.
    private weak var parentWindow: NSWindow?

    @objc private func parentDidEndSheet(_ notification: Notification) {
        // The notification names the parent, not which of its sheets ended.
        guard let parent = parentWindow, let window = view.window,
              !parent.sheets.contains(window) else { return }
        finish(dismissing: false)
    }

    /// Ends the sheet: calls `onClose` once per presentation, however many
    /// ways the end is reported, and dismisses the sheet when the end starts
    /// here (Done) rather than being reported after the fact. Internal so a
    /// test can close a sheet it never put on screen.
    func finish(dismissing: Bool = true) {
        guard !hasClosed else { return }
        hasClosed = true
        if let parent = parentWindow {
            NotificationCenter.default.removeObserver(self, name: NSWindow.didEndSheetNotification, object: parent)
        }
        parentWindow = nil
        if dismissing, presentingViewController != nil { dismiss(self) }
        onClose?()
    }

    @objc private func close(_ sender: Any?) {
        finish()
    }
}
