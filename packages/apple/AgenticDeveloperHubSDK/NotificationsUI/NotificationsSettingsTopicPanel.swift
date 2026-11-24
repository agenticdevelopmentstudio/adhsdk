import AppKit
import AgenticDeveloperHubSDK
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKMacOS
import AgenticDeveloperHubSDKNotifications

/// The one "Notifications" settings topic. Its topic list holds the host's
/// own notification settings as "General", then the shared ones: "Styles"
/// (only the list of urgency styles), "Overrides" and "Behavior".
///
/// The host passes in `general` because what it holds — sounds, filters,
/// history — is the host's; everything after it is the presentation layer's
/// and lives here, so every app that links NotificationsUI gets the same
/// topics.
@MainActor
public final class NotificationsSettingsTopicPanel: ComposableSettings.SettingsPanelSplitViewController {

    private let general: any ComposableSettingsPanel
    let styles: NotificationStylesSettingsPanel
    let crawl: NotificationCrawlSettingsPanel
    private let extraTopics: [ComposableSettings.SettingsPanelViewController]
    let overrides: NotificationOverridesSettingsPanel
    let behavior: NotificationBehaviorSettingsPanel

    public init(
        general: any ComposableSettingsPanel,
        handler: NoticeActionHandler,
        store: SettingsStore = UserSettings.shared,
        extraTopics: [ComposableSettings.SettingsPanelViewController] = []
    ) {
        self.general = general
        self.styles = NotificationStylesSettingsPanel(handler: handler, store: store)
        self.crawl = NotificationCrawlSettingsPanel(store: store)
        self.extraTopics = extraTopics
        self.overrides = NotificationOverridesSettingsPanel(store: store)
        self.behavior = NotificationBehaviorSettingsPanel(store: store)
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "Notifications",
            icon: NSImage(systemSymbolName: "bell.badge", accessibilityDescription: "Notifications")))
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }

    /// The topics in sidebar order.
    var topics: [any ComposableSettingsPanel] { [general, styles, crawl, overrides, behavior] + extraTopics }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setPanels(topics)
    }
}
