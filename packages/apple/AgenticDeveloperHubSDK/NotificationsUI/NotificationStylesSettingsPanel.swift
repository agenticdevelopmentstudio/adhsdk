import AppKit
import AgenticDeveloperHubSDK
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKMacOS
import AgenticDeveloperHubSDKNotifications

/// "Styles": only the list of styles — one topic per urgency (FYI,
/// Eventually, Soon, Now, Emergency), each a `NotificationStylePanel` with
/// the same set of properties. Nested under `NotificationsSettingsTopicPanel`;
/// everything that is not one urgency's style lives in a sibling topic there.
///
/// Also the home of the titles and samples every Notifications topic shares.
@MainActor
public final class NotificationStylesSettingsPanel: ComposableSettings.SettingsPanelSplitViewController {

    /// One panel per urgency, in `Notice.Urgency.allCases` order.
    let urgencyPanels: [NotificationStylePanel]

    public init(handler: NoticeActionHandler, store: SettingsStore = UserSettings.shared) {
        self.urgencyPanels = Notice.Urgency.allCases.map {
            NotificationStylePanel(urgency: $0, handler: handler, store: store)
        }
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "Styles",
            icon: NSImage(systemSymbolName: "rectangle.stack", accessibilityDescription: "Styles")))
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setPanels(urgencyPanels)
    }

    /// The panel for `urgency`.
    func panel(for urgency: Notice.Urgency) -> NotificationStylePanel? {
        urgencyPanels.first { $0.urgency == urgency }
    }

    // MARK: Shared titles and samples

    /// A new sample each time, so the host never deduplicates it away.
    static func sample(for urgency: Notice.Urgency) -> Notice {
        Notice(
            source: "notification-styles",
            title: "Test: \(title(for: urgency))",
            body: "This is how a \(title(for: urgency).lowercased()) notice looks.",
            urgency: urgency,
            category: "test",
            actions: [.init(id: "ok", label: "OK", kind: .callback)])
    }

    static func title(for urgency: Notice.Urgency) -> String {
        switch urgency {
        case .fyi: "FYI"
        case .eventually: "Eventually"
        case .soon: "Soon"
        case .now: "Now"
        case .emergency: "Emergency"
        }
    }

    static func symbol(for urgency: Notice.Urgency) -> String {
        switch urgency {
        case .fyi: "info.circle"
        case .eventually: "clock"
        case .soon: "exclamationmark.circle"
        case .now: "exclamationmark.triangle"
        case .emergency: "light.beacon.max"
        }
    }

    /// An urgency's own profile, as the user set it: never bent by an
    /// override, which a sample notice could match.
    static func baseProfile(for urgency: Notice.Urgency, in rules: NoticeRoutingRules) -> NoticeProfile {
        rules.profiles[urgency] ?? NoticeRoutingRules.defaultProfile(for: urgency)
    }

    static func describe(_ override: NoticeRoutingRules.Override) -> String {
        var match: [String] = []
        if let source = override.source { match.append("source \(source)") }
        if let category = override.category { match.append("category \(category)") }
        if let urgency = override.urgency { match.append(title(for: urgency)) }
        return "\(match.joined(separator: ", ")) → \(styleTitle(override.profile.style))"
    }

    static func styleTitle(_ style: NoticeProfile.Style) -> String {
        switch style {
        case .toast: "Toast"
        case .crawl: "Crawl"
        case .fullScreen: "Full screen"
        case .alert: "Alert"
        case .system: "Notification Center"
        case .none: "Don't show"
        }
    }

    static func positionTitle(_ position: NoticeProfile.Position) -> String {
        switch position {
        case .topLeft: "Top left"
        case .topCenter: "Top center"
        case .topRight: "Top right"
        case .center: "Center"
        case .bottomLeft: "Bottom left"
        case .bottomCenter: "Bottom center"
        case .bottomRight: "Bottom right"
        }
    }

    static func screensTitle(_ screens: NoticeProfile.ScreenSelection) -> String {
        switch screens {
        case .main: "Main screen"
        case .cursor: "Screen with the pointer"
        case .all: "Every screen"
        }
    }
}
