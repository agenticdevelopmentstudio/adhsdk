//
//  BrowserBehaviorPanel.swift
//  AgenticDeveloperHubSDK
//

import AppKit

import AgenticDeveloperHubSDKCore

/// The Browser panel's Behavior topic: what a browser does — where File ▸ New
/// opens a site, whether a page runs JavaScript or opens windows of its own,
/// what a new pane opens on, and whether media plays without a click.
///
/// Every control here moved from General or Media and Permissions and keeps
/// its setting key and accessibility identifier: only its topic changed
/// (`keys-never-change`, `optimize-for-change`). "Open sites in tabs" governs
/// a window's New command, not a pane, so it is shown only in the app's
/// Settings window.
@MainActor
final class BrowserBehaviorPanel: BrowserTopicPanel {

    init(binding: BrowserSettingsBinding) {
        super.init(title: "Behavior", symbol: "hand.tap", binding: binding)
    }

    /// One topic per group the topic shows: Open Sites in Tabs only in the
    /// Settings window, where its group is.
    override var helpContent: ComposableSettings.PanelHelp? {
        let windows: [ComposableSettings.PanelHelp.Topic] = binding.isPaneScope ? [] : [
            .init(
                title: "Open Sites in Tabs",
                body: "File ▸ New (⌘N) over a web browser window normally opens another web "
                    + "browser window. With this on, it opens a new tab in the window in front "
                    + "instead, as File ▸ New Tab does. It is set for the whole app, so it is "
                    + "in the Settings window only."
            )
        ]
        return ComposableSettings.PanelHelp(topics: windows + Self.pageHelpTopics)
    }

    private static let pageHelpTopics: [ComposableSettings.PanelHelp.Topic] = [
        .init(
            title: "Page",
            body: "Enable JavaScript, turned off, applies to the next page each pane loads, "
                + "and most of the web stops working without it; in a Chrome pane it applies "
                + "at once. "
                + "Block pop-up windows refuses a window a page opens on its own; a link that "
                + "opens a new window still loads, in the same pane."
        ),
        .init(
            title: "Home Page",
            body: "What a new browser pane opens on when it has no page to go back to. "
                + "Blank opens an empty page, with the address bar ready. A bare host "
                + "such as example.com gets https:// in front, exactly as it would in "
                + "the address bar. A pane that was closed on a page reopens on that "
                + "page, not the home page."
        ),
        .init(
            title: "Playback",
            body: "Autoplay decides whether a page may start video or audio without a "
                + "click: allowed, only without sound (the usual browser default — a "
                + "muted video plays, one with sound waits), or never. A Safari pane "
                + "fixes it when the pane is created: in the Settings window it applies "
                + "to Safari panes opened after the change, and in a Safari pane's "
                + "settings when the sheet closes. Chromium reads it once when it "
                + "starts, so Chrome panes follow it the next time the app opens. Never "
                + "in a Chrome pane still lets a muted video play: Chromium has no "
                + "policy that stops one. AirPlay is Safari's alone and is in General."
        )
    ]

    /// Every control's title, then the other words someone might search by.
    static let keywords: [String] = [
        "Open sites in tabs", "Enable JavaScript", "Block pop-up windows", "Home page", "Autoplay",
        "new opens tabs", "new tab", "start page", "javascript", "pop-up", "popup",
        "playback", "video", "audio", "behavior"
    ]

    override var searchKeywords: [String] { Self.keywords }

    override func viewDidLoad() {
        super.viewDidLoad()
        // A window's New, not a pane's: shown only in the app's Settings.
        if !binding.isPaneScope {
            settingsView.addGroup(makeWindowsGroup())
        }
        settingsView.addGroup(makePageGroup())
        settingsView.addGroup(makeHomeGroup())
        settingsView.addGroup(makePlaybackGroup())
    }

    private func makeWindowsGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Windows")
        let tabs = binding.model("Open sites in tabs", UserSettings.browserNewOpensTabs)
        let checkbox = ComposableSettings.CheckboxView(with: tabs)
        // On the toggle, as every other row's is: on the row's container it
        // was set but never reached the accessibility tree.
        _ = checkbox.toggle.accessibilityID("settings.browser.general.new-opens-tabs")
        binding.add(checkbox, model: tabs, key: UserSettings.browserNewOpensTabs, to: group)
        return group
    }

    private func makePageGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Page")

        // What it does is in the topic's help (`no-inline-help-labels`).
        let javaScript = binding.model("Enable JavaScript", UserSettings.browserJavaScriptEnabled)
        let javaScriptView = ComposableSettings.CheckboxView(with: javaScript)
        _ = javaScriptView.toggle.accessibilityID("settings.browser.general.javascript")
        binding.add(javaScriptView, model: javaScript, key: UserSettings.browserJavaScriptEnabled, to: group)

        let popups = binding.model("Block pop-up windows", UserSettings.browserBlocksPopups)
        let popupsView = ComposableSettings.CheckboxView(with: popups)
        _ = popupsView.toggle.accessibilityID("settings.browser.general.block-popups")
        binding.add(popupsView, model: popups, key: UserSettings.browserBlocksPopups, to: group)

        return group
    }

    private func makeHomeGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Home Page")
        // What it does is in the topic's help (`no-inline-help-labels`).
        let home = binding.model("Address", UserSettings.browserHomePage)
        let field = ComposableSettings.TextEditView(with: home)
        field.textField.placeholderString = "example.com"
        _ = field.textField.accessibilityID("settings.browser.general.home-page")
        binding.add(field, model: home, key: UserSettings.browserHomePage, to: group)
        return group
    }

    private func makePlaybackGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Playback")
        let autoplay = binding.choice(
            "Autoplay", UserSettings.browserAutoplay,
            choices: BrowserAutoplayPolicy.allCases.map { .init(label: $0.label, value: $0) },
            explanation: autoplayNote
        )
        let autoplayView = ComposableSettings.PopupMenuChoiceView(viewModel: autoplay)
        _ = autoplayView.popUpButton.accessibilityID("settings.browser.media.autoplay")
        binding.add(autoplayView, model: autoplay, key: UserSettings.browserAutoplay, to: group)
        return group
    }

    /// When autoplay takes effect differs by engine: a Safari pane fixes it
    /// when its page is made, Chromium once when it starts.
    private var autoplayNote: String {
        guard let pane = binding.pane else {
            return "Applies to Safari panes opened after the change, and to Chrome "
                + "panes the next time the app opens."
        }
        switch pane.engineKind {
        case .safari: return binding.constructionNote(for: UserSettings.browserAutoplay.name)
        case .chrome: return "Chrome panes all follow the Settings window's value, "
            + "from the next time the app opens."
        }
    }
}
