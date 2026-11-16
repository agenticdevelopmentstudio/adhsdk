//
//  SessionPrivacySettingsPanel.swift
//  AgenticDeveloperHubSDK
//

import AppKit

import AgenticDeveloperHubSDKCore

/// The Browser panel's Privacy and Security topic: what a page can learn of
/// the person using it — keyboard, mouse, pointer, drags, focus and
/// visibility (spec section 10's Session Privacy) — what the agent may do
/// with the pane and whether models see it through the privacy words (Agent
/// Privacy, built by `AgentPrivacySettingsGroup`), which cookie jar it keeps,
/// and which third-party scripts it runs. After those, the groups that were
/// topics of their own: Cookies, Camera and Microphone, Safari's Protection,
/// Site Data (a button that opens `BrowserSiteDataWindowController`) and
/// History's recording options. Every moved row keeps its key and its
/// accessibility identifier (`keys-never-change`).
///
/// Protection and Site Data are WebKit's alone, so a Chrome pane's sheet
/// leaves them out, as General leaves out AirPlay and Web Inspector
/// (`principle-of-least-astonishment`).
///
/// Every row binds through the panel's `BrowserSettingsBinding`, so the same
/// topic is the Settings window's global one and a pane's own in its sheet
/// (`dry`). The help says plainly which protections are enforced natively and
/// which are best-effort, and offers no setting for what a page cannot see
/// anyway — screenshots — rather than a switch that would protect nothing
/// (`principle-of-least-astonishment`).
@MainActor
final class BrowserPrivacySettingsPanel: BrowserTopicPanel {

    /// Builds the Agent Privacy group and opens the words editor from it.
    /// The editor's window is the panel's own unless the host names another:
    /// a popover is no window to put a sheet on.
    private lazy var agentPrivacy = AgentPrivacySettingsGroup(binding: binding) { [weak self, editorWindow] in
        editorWindow?() ?? self?.view.window
    }

    private let editorWindow: (() -> NSWindow?)?
    /// The store Manage Site Data… lists, asked each time it is pressed so
    /// a pane's sheet lists the jar Storage names then, not the one the
    /// sheet opened on; `nil` leaves the Site Data group out (a Chrome
    /// pane's sheet).
    private let siteData: (() -> BrowserSiteData?)?
    /// Whether the host records visits anywhere, in global scope. A pane
    /// answers for itself.
    private let hasHistoryStore: Bool
    /// Kept while the Site Data window is up.
    private var siteDataWindow: BrowserSiteDataWindowController?

    /// - Parameters:
    ///   - siteData: the store the Site Data window lists, resolved when
    ///     Manage Site Data… is pressed — the global jar's in the Settings
    ///     window, the jar the pane's Storage setting names in its sheet;
    ///     `nil` for no Site Data group.
    ///   - hasHistoryStore: whether the host records visits at all, for the
    ///     Settings window; a pane's sheet asks the pane.
    ///   - editorWindow: the window Edit Privacy Words… and Manage Site Data…
    ///     open over; `nil` uses the panel's own window.
    init(
        binding: BrowserSettingsBinding,
        siteData: (() -> BrowserSiteData?)? = nil,
        hasHistoryStore: Bool = true,
        editorWindow: (() -> NSWindow?)? = nil
    ) {
        self.editorWindow = editorWindow
        self.siteData = siteData
        self.hasHistoryStore = hasHistoryStore
        super.init(title: "Privacy and Security", symbol: "hand.raised", binding: binding)
    }

    /// False only in a Chrome pane's sheet: Protection is WebKit's alone.
    private var showsSafariOnlyGroups: Bool {
        binding.pane?.engineKind != .chrome
    }

    override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(
            topics: Self.sessionHelpTopics + AgentPrivacySettingsGroup.helpTopics + addedHelpTopics
        )
    }

    private static let sessionHelpTopics: [ComposableSettings.PanelHelp.Topic] = [
        .init(
            title: "General",
            body: "Pause all events, in a tab's privacy settings, keeps every event from "
                + "that page until you uncheck it; the privacy button turns red while it is on. "
                + "Show privacy toolbar puts a bar under the address bar that shows every "
                + "privacy setting, with the privacy button at its left end: each item is green "
                + "while the thing it names is on and red while it is off, so Keyboard is green "
                + "while the page gets the keyboard and Hide Images is green while images are "
                + "hidden. Set in "
                + "the Settings window it applies to every web browser; set in a tab's "
                + "privacy settings, to that browser alone."
        ),
        .init(
            title: "Input",
            body: "Disable keyboard events and Disable mouse and scrolling events decide "
                + "whether the page receives what you type and click. Checked, the pane drops the event before "
                + "the browser engine sees it, so the page never learns it happened; menu "
                + "shortcuts still reach the menu bar, and the address bar and the "
                + "back, forward and reload buttons still work. Disable pointer tracking "
                + "stops the page being told where the pointer is — hover, "
                + "movement, entering and leaving — and Disable drag and drop stops a drag "
                + "from outside entering the page. All four are unchecked until you check them "
                + "and are enforced natively. Pointer tracking only while the page has focus is "
                + "no longer offered here; a pane that still holds it shows Disable pointer "
                + "tracking checked, and unchecking it lets the page track the pointer. "
                + "The agent's own clicks and keys pass, unless the pane is paused "
                + "and Agent while paused says the agent pauses too."
        ),
        .init(
            title: "Focus and Visibility",
            body: "Disable activation events makes the page see a document that "
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
            title: "Coding Partner",
            body: "Agent access decides how much of this browser the agent sees: hidden "
                + "leaves the pane out of its list altogether, read only lets it read "
                + "the page, its text, its console and screenshots but not click, type "
                + "or navigate, and full control lets it drive. Agent while paused "
                + "decides whether the agent keeps driving a pane you have paused from "
                + "its browser menu. Both narrow what the master switches allow; the "
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
                + "Accept cookies and Private browsing are in Cookies, below."
        ),
        .init(
            title: "Scripts",
            body: "Third-party content blocks scripts, or everything, a page loads from "
                + "a site other than its own — the usual carrier of trackers — and "
                + "applies at once. Capture page console lets the agent read what the "
                + "page logs. It works by adding a small hook to the page's own "
                + "console, which page scripts can see. JavaScript is in Behavior, "
                + "and Lockdown Mode in Protection, below."
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
                + "except Protection and Site Data, which only WebKit has and which a "
                + "Chrome pane's settings leave out."
        )
    ]

    /// The help for the groups that were topics of their own, worded for
    /// the scope the panel is in.
    /// Whether the visits this panel's Record history governs go anywhere.
    private var recordsAnywhere: Bool { binding.pane?.hasHistoryStore ?? hasHistoryStore }

    private var addedHelpTopics: [ComposableSettings.PanelHelp.Topic] {
        var topics: [ComposableSettings.PanelHelp.Topic] = [
            .init(
                title: "Cookies",
                body: "Accept cookies decides whether sites may set cookies at all, in "
                    + "Safari and Chrome panes alike; there is no first-party-only middle. "
                    + "Off, most sites cannot keep you signed in. It belongs to the jar, "
                    + "not the pane, so in a pane's settings it can be changed only while "
                    + "the pane has a jar of its own. Private browsing gives each new "
                    + "browser pane a store of its own that is thrown away when the pane "
                    + "closes, so nothing it visits is kept, history included. It is set "
                    + "for all browser panes in the Settings window, and applies to panes "
                    + "opened after the change; a pane already open keeps the store it was "
                    + "made with."
            ),
            .init(
                title: "Camera and Microphone",
                body: "What happens when a page asks for the camera or microphone. Ask "
                    + "each time shows a sheet on the pane's window naming the site and "
                    + "the device, and the answer holds for that page. Always allow grants "
                    + "every request without asking; never allow refuses them all. macOS "
                    + "still asks once, the first time the app itself uses either device. "
                    + "Autoplay is in Behavior."
            )
        ]
        if showsSafariOnlyGroups {
            topics.append(.init(
                title: "Protection",
                body: "Safari panes only, because only WebKit offers these. Warn about "
                    + "fraudulent websites asks WebKit to check each page against Apple's "
                    + "list of known phishing and malware sites and show a warning page in "
                    + "place of a match. Upgrade known sites to HTTPS loads a site WebKit "
                    + "knows supports HTTPS over HTTPS even when the address said http; "
                    + "WebKit fixes it when a pane's web view is made. Lockdown Mode is the "
                    + "same restricted mode Safari offers: certain web technologies, fonts "
                    + "and media formats are refused, which breaks some sites in exchange "
                    + "for a smaller attack surface. It applies to the next page each pane "
                    + "loads."
            ))
        }
        if siteData != nil {
            topics.append(.init(
                title: "Site Data",
                body: "Manage Site Data… opens a window listing everything WebKit is keeping "
                    + (binding.isPaneScope
                        ? "for sites in this pane's jar, the one Storage names. "
                        : "in the global jar, the one shared by every Safari pane that "
                            + "follows it; the jars of a worktree or a single pane are "
                            + "listed in that pane's settings. ")
                    + "One row per site: cookies, local storage, caches, service workers "
                    + "and the rest, named in the second column. Select a site and press "
                    + "− to remove what it kept, which signs you out of it. Remove All "
                    + "clears every site at once, after asking. Refresh re-reads the list, "
                    + "since pages write while it is open. Done, or Escape, closes it."
            ))
        }
        topics.append(.init(
            title: "History",
            body: "With Record history on, every page a browser pane finishes loading is "
                + "written down: its address, its title and when. Off, nothing new is "
                + "written and what is already recorded stays until you clear it. A "
                + "pane in private browsing records nothing, whatever this says. "
                + (recordsAnywhere
                    ? ""
                    : "This app has no history store, so nothing is recorded whatever Record "
                        + "history says. ")
                + (binding.isPaneScope
                    ? "Every browser pane records into the same history, so how long visits "
                        + "are kept is set in the Settings window. "
                    : "Keep visits for decides how long a visit is kept: anything older is "
                        + "forgotten the next time a browser pane opens. ")
                + "To see, search or clear the visits, choose Browser ▸ Show History: the "
                + "History window lists them, and its Clear History… removes them. "
                + "Nothing here clears history."
        ))
        topics.append(.init(
            title: "Agent Can See History",
            body: "What the agent may read when it asks a browser for history. All history "
                + "is every recorded visit, as the History window shows them; Current tab "
                + "only is the back and forward list of the tab it is driving, and nothing "
                + "else; None, the default, refuses the request. It decides only what the "
                + "agent reads: what is recorded is Record history's to decide. "
                + (binding.isPaneScope
                    ? "Set here, it applies to this browser alone; Use Global Setting in the "
                        + "row's menu goes back to the Settings window's value."
                    : "Set here, it applies to every web browser that does not set its own.")
        ))
        topics.append(.init(
            title: "What Is Not Here",
            body: "There is no Do Not Track switch, because WebKit sends no such "
                + "header and the sites that honoured it have largely stopped. "
                + "Passwords are not saved by the browser pane; the system keychain "
                + "is not involved."
        ))
        return topics
    }

    /// Every control's title, then the other words someone might search by.
    static let keywords: [String] = [
        "privacy", "session privacy", "keyboard", "mouse", "scrolling", "pointer", "hover", "drag and drop",
        "focus", "visibility", "agent", "agent access", "jar", "storage", "third-party", "trackers",
        "console", "screenshots", "chrome",
        // Cookies
        "Accept cookies", "Private browsing", "cookies", "incognito", "sign out",
        // Camera and Microphone
        "When a page asks", "camera", "microphone", "permissions", "webcam",
        // Protection
        "Warn about fraudulent websites", "Upgrade known sites to HTTPS", "Lockdown Mode",
        "security", "fraud", "phishing", "https", "webkit", "safari", "tracking",
        // Site Data
        "Manage Site Data…", "site data", "local storage", "cache",
        // History
        "Record history", "Keep visits for", "Agent can see history", "history", "visits",
        "recent", "clear history", "forget",
        // What Is Not Here
        "do not track", "passwords"
    ] + AgentPrivacySettingsGroup.keywords.filter { $0 != "agent" }

    override var searchKeywords: [String] { Self.keywords }

    override func viewDidLoad() {
        super.viewDidLoad()
        settingsView.addGroup(makeGeneralGroup())
        settingsView.addGroup(makeInputGroup())
        settingsView.addGroup(makeFocusGroup())
        settingsView.addGroup(makeAgentGroup())
        settingsView.addGroup(agentPrivacy.makeGroup())
        settingsView.addGroup(makeStorageGroup())
        settingsView.addGroup(makeScriptsGroup())
        // The groups that were topics of their own, after the existing ones.
        settingsView.addGroup(makeCookiesGroup())
        settingsView.addGroup(makeCaptureGroup())
        if showsSafariOnlyGroups { settingsView.addGroup(makeProtectionGroup()) }
        if siteData != nil { settingsView.addGroup(makeSiteDataGroup()) }
        settingsView.addGroup(makeHistoryGroup())
    }

    /// Pause all events (a pane's own state, so only in a pane's settings)
    /// and whether the privacy toolbar shows.
    private func makeGeneralGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "General")
        if let pane = binding.pane {
            let model = ComposableSettings.ViewModel<Bool>(
                title: "Pause all events",
                get: { [weak pane] in pane?.isEventsPaused ?? false },
                set: { [weak pane] in pane?.setEventsPaused($0) }
            )
            let view = ComposableSettings.CheckboxView(with: model)
            _ = view.toggle.accessibilityID(Self.identifier("pause"))
            group.addSettingSubview(view)
        }
        addSwitch("Show privacy toolbar", UserSettings.browserPrivacyShowToolbar, id: "show-toolbar", to: group)
        return group
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

    /// A "Disable …" checkbox over a setting whose default lets the page
    /// have the input: checked writes `disabled`, the most private value,
    /// unchecked writes `allowed`, the default. It reads unchecked only while
    /// the setting is `allowed`, so any restriction shows as checked —
    /// pointer tracking's `whenFocused`, which no row offers but a stored
    /// value or the test harness can hold, included. Checked is always the
    /// more private choice, and unchecking always means "allowed".
    private func addDisable<Value: Codable & Sendable & Equatable>(
        _ title: String,
        _ key: UserSetting<Value>,
        disabled: Value,
        allowed: Value,
        id: String,
        to group: ComposableSettings.GroupView
    ) {
        let access = binding.accessors(key)
        let model = ComposableSettings.ViewModel<Bool>(
            title: title,
            get: { access.get() != allowed },
            set: { isDisabled in
                // Checking a box that already reads checked (a `whenFocused`
                // row) keeps the value it has rather than widening it.
                guard isDisabled != (access.get() != allowed) else { return }
                access.set(isDisabled ? disabled : allowed)
            }
        )
        let view = ComposableSettings.CheckboxView(with: model)
        _ = view.toggle.accessibilityID(Self.identifier(id))
        binding.add(view, model: model, key: key, to: group)
    }

    private func makeInputGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Input")
        addDisable(
            "Disable keyboard events", UserSettings.browserPrivacyKeyboard,
            disabled: .block, allowed: .allow, id: "keyboard", to: group
        )
        addDisable(
            "Disable mouse and scrolling events", UserSettings.browserPrivacyMouse,
            disabled: .block, allowed: .allow, id: "mouse", to: group
        )
        addDisable(
            "Disable pointer tracking", UserSettings.browserPrivacyPointerTracking,
            disabled: .never, allowed: .always, id: "pointer-tracking", to: group
        )
        addDisable(
            "Disable drag and drop", UserSettings.browserPrivacyDragAndDrop,
            disabled: false, allowed: true, id: "drag-and-drop", to: group
        )
        return group
    }

    private func makeFocusGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Focus and visibility")
        addDisable(
            "Disable activation events", UserSettings.browserPrivacyHideActivation,
            disabled: true, allowed: false, id: "hide-activation", to: group
        )
        return group
    }

    private func makeAgentGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Coding Partner")
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

    // MARK: Cookies, camera, protection, site data, history

    /// A checkbox row under an identifier of its own, for the moved rows,
    /// which keep the identifiers their old topics gave them.
    private func addCheckbox(
        _ title: String,
        _ key: UserSetting<Bool>,
        identifier: String,
        explanation: String? = nil,
        to group: ComposableSettings.GroupView
    ) {
        let model = binding.model(title, key, explanation: explanation)
        let view = ComposableSettings.CheckboxView(with: model)
        _ = view.toggle.accessibilityID(identifier)
        binding.add(view, model: model, key: key, to: group)
    }

    private func makeCookiesGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Cookies")
        addCheckbox(
            "Accept cookies", UserSettings.browserAcceptsCookies,
            identifier: "settings.browser.cookies.accept-cookies",
            explanation: cookiesExplanation, to: group
        )
        addCheckbox(
            "Private browsing", UserSettings.browserPrivateBrowsing,
            identifier: "settings.browser.cookies.private-browsing",
            explanation: "Applies to panes opened after the change.",
            to: group
        )
        return group
    }

    /// Accept cookies belongs to a jar, so in a pane's sheet the row names
    /// the one the pane is on — what the Cookies topic's title used to say.
    /// What the switch does is in the Cookies help (`no-inline-help-labels`),
    /// so the Settings window's row has no note.
    private var cookiesExplanation: String? {
        guard let pane = binding.pane else { return nil }
        return "Applies to the jar: \(BrowserSettingsPanelViewController.jarLabel(for: pane))."
    }

    private func makeCaptureGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Camera and Microphone")
        let capture = binding.choice(
            "When a page asks", UserSettings.browserMediaCapture,
            choices: BrowserMediaCapturePolicy.allCases.map { .init(label: $0.label, value: $0) }
        )
        let captureView = ComposableSettings.PopupMenuChoiceView(viewModel: capture)
        _ = captureView.popUpButton.accessibilityID("settings.browser.media.capture")
        binding.add(captureView, model: capture, key: UserSettings.browserMediaCapture, to: group)
        return group
    }

    private func makeProtectionGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Protection")
        addCheckbox(
            "Warn about fraudulent websites", UserSettings.browserFraudWarning,
            identifier: "settings.browser.safari.fraud-warning", to: group
        )
        addCheckbox(
            "Upgrade known sites to HTTPS", UserSettings.browserUpgradesToHTTPS,
            identifier: "settings.browser.safari.upgrade-https",
            explanation: binding.safariConstructionNote(for: UserSettings.browserUpgradesToHTTPS.name),
            to: group
        )
        // What it does is in the topic's help (`no-inline-help-labels`).
        addCheckbox(
            "Lockdown Mode", UserSettings.browserLockdownMode,
            identifier: "settings.browser.safari.lockdown", to: group
        )
        return group
    }

    static let manageSiteDataIdentifier = "settings.browser.site-data.manage"

    /// One button; the table is in the window it opens
    /// (`manage-site-data-button`).
    private func makeSiteDataGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Site Data")
        let manage = ComposableSettings.ButtonViewModel(title: "Manage Site Data…") { [weak self] in
            self?.manageSiteData()
        }
        let manageView = ComposableSettings.ButtonView(viewModel: manage, placement: .leading)
        manageView.button.toolTip = "List and remove what sites have stored"
        _ = manageView.button.accessibilityID(Self.manageSiteDataIdentifier)
        binding.register(manage, as: Self.manageSiteDataIdentifier)
        group.addSettingSubview(manageView)
        return group
    }

    /// The name of the jar Manage Site Data… acts on: in a pane's sheet the
    /// one its Storage (or Private browsing) setting names now, in the
    /// Settings window the global jar.
    var siteDataJarName: String {
        binding.isPaneScope
            ? WebBrowserPaneViewController.siteDataJarName(under: binding.store)
            : BrowserStorageJar.global.label
    }

    /// Resolves the store when pressed, so a Storage change made in the
    /// same sheet is the jar the window lists and Remove All… empties.
    private func manageSiteData() {
        guard siteDataWindow == nil, let siteData = siteData?(),
              let parent = editorWindow?() ?? view.window else { return }
        let jarName = siteDataJarName
        let detail = binding.isPaneScope
            ? "Cookies, caches and storage for every site in the jar \u{201C}\(jarName)\u{201D} are "
                + "removed, and the panes on it are signed out of them. History and Chrome's data are "
                + "not affected."
            : "Cookies, caches and storage for every site in the global jar are removed, and Safari "
                + "panes on it are signed out everywhere. History and Chrome's data are not affected."
        let controller = BrowserSiteDataWindowController(
            siteData: siteData, jarName: jarName, removeAllDetail: detail)
        siteDataWindow = controller
        controller.runModal(for: parent)
        siteDataWindow = nil
    }

    /// Record history, then — in the Settings window only, since the visit
    /// store is one for the whole app — Keep visits for, then Agent can see
    /// history (`history-group-contents`).
    private func makeHistoryGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "History")
        // What Record history means without a store is in the History help
        // topic, not under the checkbox.
        addCheckbox(
            "Record history", UserSettings.browserRecordsHistory,
            identifier: "settings.browser.history.record",
            to: group
        )
        if !binding.isPaneScope {
            let retention = binding.choice(
                "Keep visits for", UserSettings.browserHistoryRetention,
                choices: BrowserHistoryRetention.allCases.map { .init(label: $0.label, value: $0) }
            )
            let retentionView = ComposableSettings.PopupMenuChoiceView(viewModel: retention)
            _ = retentionView.popUpButton.accessibilityID("settings.browser.history.retention")
            binding.add(retentionView, model: retention, key: UserSettings.browserHistoryRetention, to: group)
        }
        // Per pane over global, so it binds like every other pane row and
        // gets the override marker and Use Global Setting
        // (`agent-history-access-pane-override`).
        addChoice(
            "Agent can see history", UserSettings.browserAgentHistoryAccess,
            label: \.displayName, id: "agent-history-access", to: group
        )
        return group
    }
}
