import AppKit
import Combine
import SwiftUI
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreMacOS
import AgenticDeveloperHubSDKIntegrations

/// The "Integrations" settings panel: a sidebar of the integrations added so far (today
/// only Gmail) beside the selected one's detail. `+` offers the integrations that can be
/// added, `−` removes the selected one after a confirmation.
@MainActor
open class IntegrationsSettingsPanel: ComposableSettings.SettingsPanelSplitViewController {

    private let model: GmailSettingsModel
    private let gmailPanel: GmailSettingsPanel
    /// Gmail was just picked from `+` and stays listed, in memory, until it is configured.
    private var gmailPicked = false
    private let footer = ComposableSettings.AddRemoveFooterView(
        accessibilityPrefix: "integrations.add-remove", separatorAbove: true)
    private var providerObserver: AnyCancellable?

    public init(client: MailClient) {
        let model = GmailSettingsModel(client: client)
        self.model = model
        self.gmailPanel = GmailSettingsPanel(model: model)
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "Integrations",
            icon: NSImage(systemSymbolName: "puzzlepiece.extension", accessibilityDescription: nil)
        ))
        sidebarTitle = "Integrations"
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(
                title: "Integrations",
                body: "Each row is a service whose data is kept in sync on this Mac. Add one with +, "
                    + "remove the selected one with −."
            ),
            .init(
                title: "Gmail",
                body: "Gmail needs an OAuth client JSON downloaded from Google Cloud (Desktop app). "
                    + "Once imported, add one or more accounts and choose which mail to sync. "
                    + "Sign-in tokens are kept in your login Keychain."
            )
        ])
    }

    open override var searchKeywords: [String] {
        ["integrations", "gmail", "mail", "email", "google", "oauth", "account", "sync"]
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        footer.addButton.toolTip = "Add an integration"
        footer.removeButton.toolTip = "Remove the selected integration"
        footer.onAdd = { [weak self] in self?.showAddMenu() }
        footer.onRemove = { [weak self] in self?.confirmRemoveIntegration() }
        listViewController.setFooterView(footer)
        rebuildPanels()
        providerObserver = model.$provider.sink { [weak self] _ in
            // `$provider` publishes before the new value lands; look one turn later.
            DispatchQueue.main.async { self?.rebuildIfListingChanged() }
        }
        Task { await model.reload() }
    }

    private var gmailIsAdded: Bool { model.provider?.configured == true || gmailPicked }

    private func rebuildIfListingChanged() {
        if gmailIsAdded != (panels.count == 1) { rebuildPanels() }
    }

    private func rebuildPanels() {
        let rebuilt: [any ComposableSettingsPanel] = gmailIsAdded ? [gmailPanel] : []
        setPanels(rebuilt)
        if !rebuilt.isEmpty { selectPanel(at: 0) }
        footer.isRemoveEnabled = !rebuilt.isEmpty
    }

    // MARK: - Footer

    private func showAddMenu() {
        let menu = NSMenu()
        let item = NSMenuItem(title: "Gmail", action: #selector(addGmail), keyEquivalent: "")
        item.target = self
        item.isEnabled = !gmailIsAdded
        menu.addItem(item)
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: footer.addButton.bounds.height), in: footer.addButton)
    }

    @objc private func addGmail() {
        gmailPicked = true
        rebuildPanels()
    }

    private func confirmRemoveIntegration() {
        guard gmailIsAdded else {
            RefusalFeedback.announce()
            return
        }
        let alert = NSAlert()
        alert.messageText = "Remove Gmail?"
        alert.informativeText = "This removes the OAuth client and every connected Gmail account "
            + "from this Mac, along with their stored sign-ins."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Remove")
        alert.addButton(withTitle: "Cancel")
        alert.buttons.first?.hasDestructiveAction = true

        let confirmed: () -> Void = { [weak self] in
            guard let self else { return }
            self.gmailPicked = false
            Task { await self.model.removeIntegration() }
            self.rebuildPanels()
        }
        if let window = view.window {
            alert.beginSheetModal(for: window) { response in
                if response == .alertFirstButtonReturn { confirmed() }
            }
        } else if alert.runModal() == .alertFirstButtonReturn {
            confirmed()
        }
    }
}

/// The Gmail detail: its title is the sidebar row label, its body the SwiftUI view.
@MainActor
private final class GmailSettingsPanel: ComposableSettings.SettingsPanelViewController {
    private let model: GmailSettingsModel

    init(model: GmailSettingsModel) {
        self.model = model
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "Gmail",
            icon: NSImage(systemSymbolName: "envelope", accessibilityDescription: nil)
        ))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var searchKeywords: [String] {
        ["gmail", "mail", "email", "google", "oauth", "account", "sync"]
    }

    override func loadView() {
        self.view = Self.hostingView(for: GmailSettingsView(model: model).themedRoot())
    }
}
