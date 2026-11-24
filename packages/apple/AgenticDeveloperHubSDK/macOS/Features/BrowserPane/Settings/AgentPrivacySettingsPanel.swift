//
//  AgentPrivacySettingsPanel.swift
//  AgenticDeveloperHubSDK
//

import AppKit

import AgenticDeveloperHubSDKCore

/// The Agent Privacy group of the Browser panel's Privacy and Security topic
/// (`BrowserPrivacySettingsPanel`): whether models see a browser through the
/// privacy words, and the words themselves — the private terminal's privacy
/// applied to a page.
///
/// Shown in both scopes. In the Settings window the switch is the global
/// value every browser follows; in a pane's sheet the switch is the pane's own
/// override, with the usual marker. The editor shows every word either way,
/// each with the sites it applies on (`PrivacyWord`).
/// The words are the private terminals' list, edited through the same editor
/// behind the same authentication (`dry`).
@MainActor
final class AgentPrivacySettingsGroup {

    static let switchIdentifier = "settings.browser.agent-privacy.enabled"
    static let editWordsIdentifier = "settings.browser.agent-privacy.edit-words"

    static let helpTopics: [ComposableSettings.PanelHelp.Topic] = [
        .init(
            title: "Agent Privacy",
            body: "Hide Images draws the page's pictures as an eye with a line through "
                + "it, in every frame, on the page showing and every page after: each "
                + "image and image button becomes the eye; background images (gradients "
                + "too), list bullet images and border images are removed; and videos, "
                + "canvases and embedded objects are hidden. It is a style sheet, so what "
                + "a style sheet cannot reach still shows: an image inside a component's "
                + "closed shadow root, one a page draws as generated content, and anything "
                + "on a page that rewrites itself until its next page. An agent's "
                + "screenshot is what is on screen and has no protection of its own from "
                + "Hide Images; Conceal privacy words from agents is what refuses it. "
                + "Conceal privacy words from agents makes every model that reads or "
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
                + "Each word's Sites says where it applies, as comma-separated patterns: "
                + "* is everywhere, every web page and every private terminal; "
                + "google.com/* is every page on google.com; foo.com/hi/* the pages "
                + "under foo.com/hi; *.google.com any host ending in .google.com. A "
                + "pattern with no path covers its whole site, and only * applies in a "
                + "private terminal. A word added from a pane's own settings starts on "
                + "that page's site; one added from the Settings window, on *. Opening "
                + "the list asks you to authenticate; "
                + "saving it does not ask again."
        ),
        .init(
            title: "What It Does Not Hide",
            body: "The pane draws its page, address and tab names with the stand-ins "
                + "too, each tab with the words for its own site, so the screen shows "
                + "them rather than the real words. A word that a page has encoded — inside a web address's "
                + "percent-escapes, say, or split across two elements — is not "
                + "recognised, so it can reach a model as the page wrote it. Agent "
                + "access, which hides the pane or makes it read only, works alongside "
                + "this and is unchanged by it."
        )
    ]

    static let hideImagesIdentifier = "settings.browser.agent-privacy.hide-images"

    static let keywords: [String] = [
        "images", "hide images", "agent privacy",
        "privacy words", "conceal", "stand-in", "substitution", "model", "agent",
        "private", "sites", "global"
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

        let imagesKey = UserSettings.browserPrivacyHideImages
        let images = binding.model("Hide Images", imagesKey)
        let imagesView = ComposableSettings.CheckboxView(with: images)
        _ = imagesView.toggle.accessibilityID(Self.hideImagesIdentifier)
        binding.add(imagesView, model: images, key: imagesKey, to: group)

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
    /// vault. The only prompt: the editor's Save does not ask again. Every
    /// word is shown either way; a word added from a pane's settings starts on
    /// the pane's site (`google.com/*`), one added from the Settings window
    /// on `*`.
    ///
    /// A pane's settings window is app-modal, and the authentication prompt
    /// cannot come in front of an app-modal window; the vault announces its
    /// prompt and the modal session steps aside while it is up
    /// (`SystemAuthenticationPrompt`, `AppModalWindowSession`).
    private func editWords() {
        guard !isAuthenticating, let vault = binding.privacyVault else { return }
        let newWordSite = binding.pane.map { PrivacySitePattern.defaultPattern(for: $0.privacyWordsURL) }
            ?? PrivacySitePattern.everywhere
        isAuthenticating = true
        Task { [weak self] in
            guard let self else { return }
            defer { self.isAuthenticating = false }
            do {
                try await vault.authenticate(reason: "edit the privacy words")
                guard let window = self.window() else { return }
                PrivacyWordsEditor.present(vault: vault, on: window, newWordSite: newWordSite)
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
