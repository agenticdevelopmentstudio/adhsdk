//
//  SessionPrivacySettingsPanel.swift
//  AgenticDeveloperHubSDK
//

import AppKit

import AgenticDeveloperHubSDKCore

/// The Browser panel's Session Privacy topic (spec section 10): what a page
/// can learn of the person using it — keyboard, mouse, pointer, drags, focus
/// and visibility — what the agent may do with the pane, which cookie jar it
/// keeps, and which third-party scripts it runs.
///
/// Every row binds through the panel's `BrowserSettingsBinding`, so the same
/// topic is the Settings window's global one and a pane's own in its sheet
/// (`dry`). The help says plainly which protections are enforced natively and
/// which are best-effort, and offers no setting for what a page cannot see
/// anyway — screenshots — rather than a switch that would protect nothing
/// (`principle-of-least-astonishment`).
@MainActor
final class SessionPrivacySettingsPanel: BrowserTopicPanel {

    init(binding: BrowserSettingsBinding) {
        super.init(title: "Session Privacy", symbol: "hand.raised", binding: binding)
    }

    override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(
                title: "Input",
                body: "Keyboard and Mouse and scrolling decide whether the page receives "
                    + "what you type and click. Blocked, the pane drops the event before "
                    + "the browser engine sees it, so the page never learns it happened; menu "
                    + "shortcuts still reach the menu bar, and the address bar and the "
                    + "back, forward and reload buttons still work. Pointer tracking "
                    + "decides when the page is told where the pointer is — hover, "
                    + "movement, entering and leaving — and Drag and drop whether a drag "
                    + "from outside may enter the page. All four are enforced natively. "
                    + "The agent's own clicks and keys pass, unless the pane is paused "
                    + "and Agent while paused says the agent pauses too."
            ),
            .init(
                title: "Focus and Visibility",
                body: "Hide focus and visibility changes makes the page see a document that "
                    + "is always focused and visible, so it cannot tell when you switch to "
                    + "another window or app. It is best-effort: a script installed before "
                    + "the page's own answers the page's questions about focus and "
                    + "visibility and swallows the window-level events, and a determined "
                    + "page can still detect it. It cannot stop the blur and focusout "
                    + "events of a single element on the page — when a field loses focus, "
                    + "the page can still see that. The script applies from the next page "
                    + "load; the native part, which keeps the page painting while its "
                    + "window is covered, applies at once."
            ),
            .init(
                title: "Agent Partner",
                body: "Agent access decides how much of this browser the agent sees: hidden "
                    + "leaves the pane out of its list altogether, read only lets it read "
                    + "the page, its text, its console and screenshots but not click, type "
                    + "or navigate, and full control lets it drive. Agent while paused "
                    + "decides whether the agent keeps driving a pane you have paused from "
                    + "its gear menu. Both narrow what the master switches allow; the "
                    + "master switches themselves live in the Automation settings and "
                    + "apply to every pane."
            ),
            .init(
                title: "Storage",
                body: "The cookie and storage jar is where a pane keeps cookies, local "
                    + "storage and caches — what keeps you signed in. There are three: "
                    + "one shared by all browser panes; one shared within this worktree, "
                    + "which every browser pane opened on the same worktree folder uses, "
                    + "whatever the window; and one for this pane alone. A jar is deleted "
                    + "when the panes using it are removed: a pane's own jar when that "
                    + "pane is removed, a worktree's when the last pane on it is. "
                    + "Closing a window deletes nothing. Changing the jar reloads the "
                    + "page in the new jar, signed out of whatever the old one held. "
                    + "Accept cookies and Private browsing are in Cookies and Site Data."
            ),
            .init(
                title: "Scripts",
                body: "Third-party content blocks scripts, or everything, a page loads from "
                    + "a site other than its own — the usual carrier of trackers — and "
                    + "applies at once. Capture page console lets the agent read what the "
                    + "page logs. It works by adding a small hook to the page's own "
                    + "console, which page scripts can see. JavaScript and Lockdown Mode "
                    + "are in General and in Privacy and Security."
            ),
            .init(
                title: "Screenshots",
                body: "A screenshot of a pane, taken by you or the agent, reads the pixels "
                    + "the page has already drawn. The page cannot observe it, so there is "
                    + "nothing to hide and no setting for it."
            ),
            .init(
                title: "Chrome Panes",
                body: "Every setting here applies to Chrome panes as well as Safari ones, "
                    + "with three differences. Third-party content is judged by a site's last two name "
                    + "parts (three for names like example.co.uk), so a few shared "
                    + "hosting domains count as one site. Hiding focus and visibility "
                    + "does not reach frames from other sites that are already showing "
                    + "when it is turned on; they pick it up on the next page load. And "
                    + "Chrome does not honour Autoplay set to Never."
            )
        ])
    }

    static let keywords: [String] = [
        "session privacy", "keyboard", "mouse", "scrolling", "pointer", "hover", "drag and drop",
        "focus", "visibility", "agent", "agent access", "jar", "storage", "third-party", "trackers",
        "console", "screenshots", "chrome"
    ]

    override var searchKeywords: [String] { Self.keywords }

    override func viewDidLoad() {
        super.viewDidLoad()
        settingsView.addGroup(makeInputGroup())
        settingsView.addGroup(makeFocusGroup())
        settingsView.addGroup(makeAgentGroup())
        settingsView.addGroup(makeStorageGroup())
        settingsView.addGroup(makeScriptsGroup())
    }

    private static func identifier(_ row: String) -> String {
        "settings.browser.session-privacy.\(row)"
    }

    /// A pop-up row over an enum's labels.
    private func addChoice<Value: Codable & Sendable & Equatable & CaseIterable>(
        _ title: String,
        _ key: UserSetting<Value>,
        label: (Value) -> String,
        id: String,
        explanation: String? = nil,
        to group: ComposableSettings.GroupView
    ) {
        let model = binding.choice(
            title, key,
            choices: Value.allCases.map { .init(label: label($0), value: $0) },
            explanation: explanation
        )
        let view = ComposableSettings.PopupMenuChoiceView(viewModel: model)
        _ = view.popUpButton.accessibilityID(Self.identifier(id))
        binding.add(view, model: model, key: key, to: group)
    }

    /// A switch row.
    private func addSwitch(
        _ title: String,
        _ key: UserSetting<Bool>,
        id: String,
        explanation: String? = nil,
        to group: ComposableSettings.GroupView
    ) {
        let model = binding.model(title, key, explanation: explanation)
        let view = ComposableSettings.CheckboxView(with: model)
        _ = view.toggle.accessibilityID(Self.identifier(id))
        binding.add(view, model: model, key: key, to: group)
    }

    private func makeInputGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Input")
        addChoice("Keyboard", UserSettings.browserPrivacyKeyboard, label: \.label, id: "keyboard", to: group)
        addChoice("Mouse and scrolling", UserSettings.browserPrivacyMouse, label: \.label, id: "mouse", to: group)
        addChoice(
            "Pointer tracking", UserSettings.browserPrivacyPointerTracking,
            label: \.label, id: "pointer-tracking", to: group
        )
        addSwitch("Drag and drop", UserSettings.browserPrivacyDragAndDrop, id: "drag-and-drop", to: group)
        return group
    }

    private func makeFocusGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Focus and visibility")
        addSwitch(
            "Hide focus and visibility changes", UserSettings.browserPrivacyHideActivation,
            id: "hide-activation", to: group
        )
        return group
    }

    private func makeAgentGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Agent Partner")
        addChoice("Agent access", UserSettings.browserPrivacyAgentAccess, label: \.label, id: "agent-access", to: group)
        addChoice(
            "Agent while paused", UserSettings.browserPrivacyAgentWhilePaused,
            label: \.label, id: "agent-while-paused", to: group
        )
        return group
    }

    private func makeStorageGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Storage")
        let key = UserSettings.browserPrivacyStorageJar
        addChoice(
            "Cookie and storage jar", key, label: \.label, id: "storage-jar",
            explanation: binding.constructionNote(for: key.name), to: group
        )
        return group
    }

    private func makeScriptsGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Scripts")
        addChoice(
            "Third-party content", UserSettings.browserPrivacyThirdPartyContent,
            label: \.label, id: "third-party-content", to: group
        )
        let console = UserSettings.browserPrivacyConsoleCapture
        addSwitch(
            "Capture page console", console, id: "console-capture",
            explanation: binding.constructionNote(for: console.name),
            to: group
        )
        return group
    }
}
