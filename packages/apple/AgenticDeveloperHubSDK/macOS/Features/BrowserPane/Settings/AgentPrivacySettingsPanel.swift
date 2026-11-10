//
//  AgentPrivacySettingsPanel.swift
//  AgenticDeveloperHubSDK
//

import AppKit

import AgenticDeveloperHubSDKCore

/// A browser pane's Agent Privacy topic: whether models see this pane through
/// the privacy words, and the words themselves — the private terminal's
/// privacy applied to a page.
///
/// Listed in a pane's settings sheet only. The switch is the pane's alone
/// (`BrowserSettings.paneOnlyKeyNames`), so its row has no override marker
/// and nothing in the Settings window to fall back to. The words are the
/// private terminals' list, edited through the same editor behind the same
/// authentication (`dry`).
@MainActor
final class AgentPrivacySettingsPanel: BrowserTopicPanel {

    static let switchIdentifier = "settings.browser.agent-privacy.enabled"
    static let editWordsIdentifier = "settings.browser.agent-privacy.edit-words"

    private var isAuthenticating = false

    init(binding: BrowserSettingsBinding) {
        super.init(title: "Agent Privacy", symbol: "eye.slash", binding: binding)
    }

    override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(
                title: "Agent Privacy",
                body: "Conceal privacy words from agents makes every model that reads or "
                    + "drives this pane see it through the privacy words: each real word in "
                    + "what a browser tool hands back — the page's text, its snapshot, its "
                    + "title and address, its console, the pane's row in the list of browser "
                    + "panes, and any error — is replaced by its stand-in before the model "
                    + "reads it. What a model types, fills, selects, searches for or "
                    + "navigates to has its stand-ins turned back into the real words before "
                    + "the page receives it, so it can still work with what it cannot see. "
                    + "While it is on, the pane's title bar shows an eye with a slash "
                    + "through it. It is off for every new pane."
            ),
            .init(
                title: "Refused Tools",
                body: "Three tools cannot be concealed, so a pane with Agent Privacy on "
                    + "refuses them: a screenshot, which is the page's pixels; a click at a "
                    + "point, which is aimed from a screenshot; and evaluating JavaScript, "
                    + "whose answer can be any part of the page in any form. If the privacy "
                    + "words cannot be read without asking you — the keychain refused them — "
                    + "the pane refuses every tool until they can be, rather than show the "
                    + "page unconcealed."
            ),
            .init(
                title: "Privacy Words",
                body: "The words are the same list the private terminals use: one list, "
                    + "kept in the keychain, and an edit applies to every private terminal "
                    + "and every browser pane with Agent Privacy on at once. Opening the "
                    + "list asks you to authenticate."
            ),
            .init(
                title: "What It Does Not Hide",
                body: "The page on your screen is not changed: you still see the real "
                    + "words. A word that a page has encoded — inside a web address's "
                    + "percent-escapes, say, or split across two elements — is not "
                    + "recognised, so it can reach a model as the page wrote it. Agent "
                    + "access in Session Privacy, which hides the pane or makes it read "
                    + "only, works alongside this and is unchanged by it."
            )
        ])
    }

    static let keywords: [String] = [
        "agent privacy", "privacy words", "conceal", "stand-in", "substitution", "model", "agent",
        "private"
    ]

    override var searchKeywords: [String] { Self.keywords }

    override func viewDidLoad() {
        super.viewDidLoad()
        let group = ComposableSettings.GroupView(withTitle: "Agent Privacy")
        let key = UserSettings.browserAgentPrivacy
        let model = binding.model("Conceal privacy words from agents", key)
        let view = ComposableSettings.CheckboxView(with: model)
        _ = view.toggle.accessibilityID(Self.switchIdentifier)
        binding.add(view, model: model, key: key, to: group)

        if binding.pane?.privacyVault != nil {
            let edit = ComposableSettings.ButtonViewModel(title: "Edit Privacy Words…") { [weak self] in
                self?.editWords()
            }
            let editView = ComposableSettings.ButtonView(viewModel: edit, placement: .leading)
            _ = editView.button.accessibilityID(Self.editWordsIdentifier)
            binding.register(edit, as: Self.editWordsIdentifier)
            group.addSettingSubview(editView)
        }
        settingsView.addGroup(group)
    }

    /// Authenticates, then opens the privacy words editor over this sheet —
    /// the private terminal's Edit Privacy Words, over the same vault.
    private func editWords() {
        guard !isAuthenticating, let vault = binding.pane?.privacyVault else { return }
        isAuthenticating = true
        Task { [weak self] in
            guard let self else { return }
            defer { self.isAuthenticating = false }
            do {
                try await vault.authenticate(reason: "edit the privacy words")
                guard let window = self.view.window else { return }
                PrivacyWordsEditor.present(vault: vault, on: window)
            } catch {
                guard let window = self.view.window else { return }
                let alert = NSAlert()
                alert.messageText = "The privacy words could not be opened."
                alert.informativeText = error.localizedDescription
                alert.beginSheetModal(for: window, completionHandler: nil)
            }
        }
    }
}
