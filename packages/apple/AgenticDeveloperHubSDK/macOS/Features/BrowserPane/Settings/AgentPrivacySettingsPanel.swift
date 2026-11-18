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
/// override, with the usual marker. Open Secrets… opens the Secrets window,
/// where the words are kept, each with the sites and terminals it applies in
/// (`PrivacyWord`): the private terminals' list, behind the window's own
/// authentication (`dry`).
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
            title: "Let models drive browser panes",
            body: "A model — Claude Code in a terminal pane, or the app's own chat — can drive "
                + "the browser panes: read the page, click, type, and take screenshots. Off, a "
                + "model can still list the browser panes but cannot read or act on them. Set "
                + "in the Settings window only; it applies to every browser pane."
        ),
        .init(
            title: "Allow browser_evaluate",
            body: "Lets a model run JavaScript it wrote in a page. Off by default: every other "
                + "tool is bounded by what the page offers; this one is not."
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
    /// The automation switches keep the identifiers they had in the
    /// Automation panel they came from.
    static let automationEnabledIdentifier = "settings.automation.enabled"
    static let automationEvaluateIdentifier = "settings.automation.evaluate"

    static let keywords: [String] = [
        "images", "hide images", "agent privacy",
        "privacy words", "conceal", "stand-in", "substitution", "model", "agent",
        "private", "sites", "global",
        "automation", "drive", "evaluate", "javascript", "mcp",
        "Let models drive browser panes", "Allow browser_evaluate", "secrets"
    ]

    private let binding: BrowserSettingsBinding

    init(binding: BrowserSettingsBinding) {
        self.binding = binding
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

        // Whether models may drive a browser at all: one global switch pair,
        // so the Settings window shows it and a pane's sheet does not.
        if !binding.isPaneScope { addAutomationRows(to: group) }

        if binding.privacyVault != nil {
            let edit = ComposableSettings.ButtonViewModel(title: "Open Secrets…") { [weak self] in
                self?.editWords()
            }
            let editView = ComposableSettings.ButtonView(viewModel: edit, placement: .leading)
            _ = editView.button.accessibilityID(Self.editWordsIdentifier)
            binding.register(edit, as: Self.editWordsIdentifier)
            group.addSettingSubview(editView)
        }
        return group
    }

    private func addAutomationRows(to group: ComposableSettings.GroupView) {
        let enabledKey = UserSettings.browserAutomationEnabled
        let enabled = binding.model("Let models drive browser panes", enabledKey)
        let enabledView = ComposableSettings.CheckboxView(with: enabled)
        _ = enabledView.toggle.accessibilityID(Self.automationEnabledIdentifier)
        binding.add(enabledView, model: enabled, key: enabledKey, to: group)

        let evaluateKey = UserSettings.browserAutomationEvaluate
        let evaluate = binding.model("Allow browser_evaluate", evaluateKey)
        let evaluateView = ComposableSettings.CheckboxView(with: evaluate)
        _ = evaluateView.toggle.accessibilityID(Self.automationEvaluateIdentifier)
        binding.add(evaluateView, model: evaluate, key: evaluateKey, to: group)
    }

    /// Opens the Secrets window, which shows hidden and asks for
    /// authentication itself. A word added from a pane's settings starts on
    /// the pane's site (`google.com/*`), one added from the Settings window
    /// on `*`.
    private func editWords() {
        guard let vault = binding.privacyVault else { return }
        let newWordSite = binding.pane.map { PrivacySitePattern.defaultPattern(for: $0.privacyWordsURL) }
            ?? PrivacySitePattern.everywhere
        SecretsWindowController.show(vault: vault, newWordSite: newWordSite)
    }
}
