//
//  AgentPrivacySettingsPanel.swift
//  AgenticDeveloperHubSDK
//

import AppKit

import AgenticDeveloperHubSDKCore

/// The Agent Privacy group of the Browser panel's Privacy topic
/// (`BrowserPrivacySettingsPanel`): whether models see a browser through the
/// privacy words, and the words themselves — the private terminal's privacy
/// applied to a page.
///
/// Shown in both scopes. In the Settings window the switch is the global
/// value every browser follows and the editor shows the global words; in a
/// pane's sheet the switch is the pane's own override, with the usual marker,
/// and the editor shows the global words and the pane's own (`PrivacyWord`).
/// The words are the private terminals' list, edited through the same editor
/// behind the same authentication (`dry`).
@MainActor
final class AgentPrivacySettingsGroup {

    static let switchIdentifier = "settings.browser.agent-privacy.enabled"
    static let editWordsIdentifier = "settings.browser.agent-privacy.edit-words"

    static let helpTopics: [ComposableSettings.PanelHelp.Topic] = [
        .init(
            title: "Agent Privacy",
            body: "Conceal privacy words from agents makes every model that reads or "
                + "drives a browser see it through the privacy words: each real word in "
                + "what a browser tool hands back — the page's text, its snapshot, its "
                + "title and address, its console, the pane's row in the list of browser "
                + "panes, and any error — is replaced by its stand-in before the model "
                + "reads it. What a model types, fills, selects, searches for or "
                + "navigates to has its stand-ins turned back into the real words before "
                + "the page receives it, so it can still work with what it cannot see. "
                + "Set here in the Settings window, it applies to every web browser; set "
                + "in a pane's own settings, to that pane alone. While it is on, the "
                + "pane's title bar shows an eye with a slash through it. It is off "
                + "until you turn it on."
        ),
        .init(
            title: "Refused Tools",
            body: "Three tools cannot be concealed, so a pane with Agent Privacy on "
                + "refuses them: a screenshot, which is the page's pixels; a click at a "
                + "point, which is aimed from a screenshot; and evaluating JavaScript, "
                + "whose answer can be any part of the page in any form. If the privacy "
                + "words cannot be read without asking you — the keychain refused them — "
                + "the pane refuses every tool until they can be, rather than show the "
                + "page unconcealed. The same happens when one word's stand-in contains "
                + "another's real word, as when two words swap: a page cannot be "
                + "concealed reliably with those words, so the pane refuses every tool, "
                + "and draws the page as it is, until they are changed."
        ),
        .init(
            title: "Privacy Words",
            body: "The words are one list, kept in the keychain and shared with the "
                + "private terminals. Each word can be turned off without deleting it. "
                + "A global word applies to every private terminal and every web browser "
                + "with Agent Privacy on; the words edited from the Settings window are "
                + "all global. A word added in a pane's own settings applies to that "
                + "browser alone unless its Global box is checked, so a browser uses the "
                + "global words and its own. Opening the list asks you to authenticate; "
                + "saving it does not ask again."
        ),
        .init(
            title: "What It Does Not Hide",
            body: "The page on your screen is not changed: you still see the real "
                + "words. A word that a page has encoded — inside a web address's "
                + "percent-escapes, say, or split across two elements — is not "
                + "recognised, so it can reach a model as the page wrote it. Agent "
                + "access, which hides the pane or makes it read only, works alongside "
                + "this and is unchanged by it."
        )
    ]

    static let keywords: [String] = [
        "agent privacy", "privacy words", "conceal", "stand-in", "substitution", "model", "agent",
        "private", "global"
    ]

    private let binding: BrowserSettingsBinding
    /// The window the editor opens over: the panel's, asked for when the
    /// button is pressed.
    private let window: () -> NSWindow?
    private var isAuthenticating = false

    init(binding: BrowserSettingsBinding, window: @escaping () -> NSWindow?) {
        self.binding = binding
        self.window = window
    }

    func makeGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Agent Privacy")
        let key = UserSettings.browserAgentPrivacy
        let model = binding.model("Conceal privacy words from agents", key)
        let view = ComposableSettings.CheckboxView(with: model)
        _ = view.toggle.accessibilityID(Self.switchIdentifier)
        binding.add(view, model: model, key: key, to: group)

        if binding.privacyVault != nil {
            let edit = ComposableSettings.ButtonViewModel(title: "Edit Privacy Words…") { [weak self] in
                self?.editWords()
            }
            let editView = ComposableSettings.ButtonView(viewModel: edit, placement: .leading)
            _ = editView.button.accessibilityID(Self.editWordsIdentifier)
            binding.register(edit, as: Self.editWordsIdentifier)
            group.addSettingSubview(editView)
        }
        return group
    }

    /// Authenticates, then opens the privacy words editor over the panel's
    /// window — the private terminal's Edit Privacy Words, over the same
    /// vault. The only prompt: the editor's Save does not ask again. A pane's
    /// sheet edits that pane's words alongside the global ones; the Settings
    /// window, the global words.
    private func editWords() {
        guard !isAuthenticating, let vault = binding.privacyVault else { return }
        let paneID = binding.pane?.privacyWordsPaneID
        isAuthenticating = true
        Task { [weak self] in
            guard let self else { return }
            defer { self.isAuthenticating = false }
            do {
                try await vault.authenticate(reason: "edit the privacy words")
                guard let window = self.window() else { return }
                PrivacyWordsEditor.present(vault: vault, on: window, paneID: paneID)
            } catch {
                guard let window = self.window() else { return }
                let alert = NSAlert()
                alert.messageText = "The privacy words could not be opened."
                alert.informativeText = error.localizedDescription
                alert.beginSheetModal(for: window, completionHandler: nil)
            }
        }
    }
}
