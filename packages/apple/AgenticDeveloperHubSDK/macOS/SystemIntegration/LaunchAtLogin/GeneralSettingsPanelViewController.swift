import AppKit
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKDatabase

/// General app-startup panel. Its explanations, including the nudge to enable
/// launch at login, live in the help drawer rather than inline.
@MainActor
public final class GeneralSettingsPanelViewController: ComposableSettings.SettingsPanelViewController {

    /// Whether Tab Behavior offers “New” menu item prefers tabs to windows,
    /// for an app whose File ▸ New can open either.
    private let showsNewPrefersTabs: Bool

    /// Whether Tab Behavior offers “Single documents open in”, for an app
    /// that opens files in Document windows (`DocumentWindowsFeature`).
    private let showsSingleDocumentsOpenIn: Bool

    public init(showsNewPrefersTabs: Bool = false, showsSingleDocumentsOpenIn: Bool = false) {
        self.showsNewPrefersTabs = showsNewPrefersTabs
        self.showsSingleDocumentsOpenIn = showsSingleDocumentsOpenIn
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "General",
            icon: NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
        ))
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static let newPrefersTabsTitle = "“New” menu item prefers tabs to windows"
    static let singleDocumentsOpenInTitle = "Single documents open in:"

    public override var helpContent: ComposableSettings.PanelHelp? {
        let newTopic = ComposableSettings.PanelHelp.Topic(
            title: Self.newPrefersTabsTitle,
            body: "File ▸ New (⌘N) over a Coding Project window normally opens another "
                + "Coding Project window, and over a File Browser window asks for a folder "
                + "to open in a new one. With this on, it opens a new tab in the window in "
                + "front instead, as File ▸ New Tab does."
        )
        let singleDocumentsTopic = ComposableSettings.PanelHelp.Topic(
            title: "Single Documents",
            body: "Where a file opened on its own lands — one chosen with Open With in the "
                + "Finder, named on the command line, or entered in File ▸ Open Location. "
                + "“\(SingleDocumentOpenMode.tabs.displayName)” gathers them as tabs of one "
                + "Document window; “\(SingleDocumentOpenMode.windows.displayName)” gives each "
                + "file a window of its own. A file that already has its own window comes "
                + "forward there either way."
        )
        let tabTopics = (showsNewPrefersTabs ? [newTopic] : [])
            + (showsSingleDocumentsOpenIn ? [singleDocumentsTopic] : [])
        return ComposableSettings.PanelHelp(topics: tabTopics + [
            .init(
                title: "Launch at Login",
                body: "\(AppStorageLocation.displayName) works best when it starts automatically "
                    + "with your Mac. Enable launch at login so you never miss a Claude Code "
                    + "session. It registers the app with macOS so it starts when you log in, using "
                    + "the system's own login-items service, so macOS lists it under General "
                    + "› Login Items and can turn it off there too — which is where to look "
                    + "if the checkbox here keeps coming back unchecked."
            ),
            .init(
                title: "Restoring Windows",
                body: "What happens to the windows you had open when the app next starts: "
                    + "reopen them all, reopen none, or ask. Restoring reopens the documents "
                    + "themselves, with their pane layout, not just empty frames."
            ),
            .init(
                title: "Tab Position",
                body: "Which edges of a tabbed window show tab bars: any of top, left, right and "
                    + "bottom, the same choice as View ▸ Tab Position. At least one edge stays on. "
                    + "A project window whose Tab Bars you set yourself keeps its own edges, and a "
                    + "browser pane can override them in its settings."
            ),
            .init(
                title: "Recent Documents",
                body: "How many entries the recent-documents list keeps. Zero switches it "
                    + "off entirely, which is the setting to use on a shared machine — the "
                    + "list is a record of what you have opened."
            )
        ])
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.settingsView.addGroup(createStartupGroup())
        self.settingsView.addGroup(createWindowBehaviorGroup())
        if showsNewPrefersTabs || showsSingleDocumentsOpenIn {
            self.settingsView.addGroup(createTabBehaviorGroup())
        }
    }

    private func createStartupGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Startup")

        group.addSettingSubview(ComposableSettings.CheckboxView(
            with: ComposableSettings.ViewModel<Bool>(
                title: "Launch at Login",
                setting: UserSettings.launchAtLogin
            )
        ))

        return group
    }

    private func createWindowBehaviorGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Window Behavior")

        let policyChoices = ReopenOnLaunchPolicy.allCases.map {
            ComposableSettings.ChoiceViewModel<ReopenOnLaunchPolicy>.Choice(
                label: $0.displayName,
                value: $0
            )
        }
        group.addSettingSubview(ComposableSettings.PopupMenuChoiceView<ReopenOnLaunchPolicy>(
            viewModel: ComposableSettings.ChoiceViewModel<ReopenOnLaunchPolicy>(
                title: "Reopen recent documents on launch:",
                setting: UserSettings.reopenOnLaunchPolicy,
                choices: policyChoices
            )
        ))

        group.addSettingSubview(ComposableSettings.StepperView(
            viewModel: ComposableSettings.RangeViewModel<Int>(
                title: "Number of recent documents:",
                setting: UserSettings.recentWindowsCount,
                minValue: 0,
                maxValue: 50
            )
        ))

        group.addSettingSubview(makeTabPositionRow())

        return group
    }

    private func createTabBehaviorGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Tab Behavior")

        if showsNewPrefersTabs {
            let checkbox = ComposableSettings.CheckboxView(with: ComposableSettings.ViewModel<Bool>(
                title: Self.newPrefersTabsTitle,
                setting: UserSettings.projectsNewOpensTabs
            ))
            _ = checkbox.accessibilityID("settings.general.new-prefers-tabs")
            group.addSettingSubview(checkbox)
        }

        if showsSingleDocumentsOpenIn {
            let choices = SingleDocumentOpenMode.allCases.map {
                ComposableSettings.ChoiceViewModel<SingleDocumentOpenMode>.Choice(
                    label: $0.displayName,
                    value: $0
                )
            }
            let popup = ComposableSettings.PopupMenuChoiceView<SingleDocumentOpenMode>(
                viewModel: ComposableSettings.ChoiceViewModel<SingleDocumentOpenMode>(
                    title: Self.singleDocumentsOpenInTitle,
                    setting: UserSettings.singleDocumentsOpenIn,
                    choices: choices
                )
            )
            _ = popup.accessibilityID("settings.general.single-documents-open-in")
            group.addSettingSubview(popup)
        }

        return group
    }

    /// The app-wide tab positions, kept in step with View ▸ Tab Position.
    private func makeTabPositionRow() -> TabPositionsSettingView {
        let row = TabPositionsSettingView(
            get: { UserSettings.tabsPositions.value },
            set: { UserSettings.tabsPositions.value = $0 },
            identifierPrefix: "settings.general.tab-position"
        )
        tabPositionsObserver = UserSettingObserver(UserSettings.tabsPositions) { [weak row] _ in
            row?.refresh()
        }
        return row
    }

    /// Follows the setting while the panel is up, for a change made from
    /// the View menu.
    private var tabPositionsObserver: UserSettingObserver<TabPositions>?
}
