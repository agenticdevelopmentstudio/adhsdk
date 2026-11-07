import AppKit
import AgenticDeveloperHubSDK
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKMacOS
import AgenticDeveloperHubSDKNotifications

/// "Styles": only the list of styles — one topic per urgency (FYI,
/// Eventually, Soon, Now, Emergency), each a `NotificationStyleSetPanel` with
/// the same set of properties. Nested under `NotificationsSettingsTopicPanel`;
/// everything that is not one urgency's style lives in a sibling topic there.
///
/// Also the home of the titles and samples every Notifications topic shares.
@MainActor
public final class NotificationStylesSettingsPanel: ComposableSettings.SettingsPanelSplitViewController {

    /// One panel per urgency, in `Notice.Urgency.allCases` order.
    let urgencyPanels: [NotificationStyleSetPanel]

    public init(handler: NoticeActionHandler, store: SettingsStore = UserSettings.shared) {
        self.urgencyPanels = Notice.Urgency.allCases.map {
            NotificationStyleSetPanel(urgency: $0, handler: handler, store: store)
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
    func panel(for urgency: Notice.Urgency) -> NotificationStyleSetPanel? {
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

    /// An urgency's own style set, as the user set it: never bent by an
    /// override, which a sample notice could match.
    static func baseStyle(for urgency: Notice.Urgency, in rules: NoticeRoutingRules) -> NoticeStyleSet {
        rules.styles[urgency] ?? NoticeRoutingRules.defaultStyle(for: urgency)
    }

    static func describe(_ override: NoticeRoutingRules.Override) -> String {
        var match: [String] = []
        if let source = override.source { match.append("source \(source)") }
        if let category = override.category { match.append("category \(category)") }
        if let urgency = override.urgency { match.append(title(for: urgency)) }
        return "\(match.joined(separator: ", ")) → \(targetTitle(override.target))"
    }

    static func targetTitle(_ target: NoticeRoutingRules.Override.Target) -> String {
        switch target {
        case .style(let urgency): "\(title(for: urgency)) style"
        case .hide: "Don't show"
        }
    }

    static func styleTitle(_ style: NoticeProfile.Style) -> String {
        switch style {
        case .toast: "Toast"
        case .crawl: "Crawl"
        case .fullScreen: "Full Screen"
        case .alert: "Alert"
        case .system: "Notification Center"
        }
    }

    static func positionTitle(_ position: NoticeProfile.Position) -> String {
        switch position {
        case .topLeft: "Top Left"
        case .topCenter: "Top Center"
        case .center: "Center"
        case .bottomLeft: "Bottom Left"
        case .bottomCenter: "Bottom Center"
        case .bottomRight: "Bottom Right"
        }
    }

    static func layerTitle(_ layer: NoticeProfile.Layer) -> String {
        layer == .floating ? "Floating" : "Normal"
    }

    static func symbol(for style: NoticeProfile.Style) -> String {
        switch style {
        case .toast: "rectangle.bottomhalf.inset.filled"
        case .alert: "exclamationmark.triangle"
        case .crawl: "arrow.left.and.right"
        case .fullScreen: "arrow.up.left.and.arrow.down.right"
        case .system: "bell"
        }
    }

    /// One item's line in the list, e.g. "Toast · Bottom Right · Floating",
    /// "Full Screen · Blur 60 % · System 55 %" or "Notification Center".
    static func describe(_ item: NoticeProfile) -> String {
        let name = styleTitle(item.style)
        switch item.style {
        case .toast, .alert:
            return [name, positionTitle(item.position), layerTitle(item.layer)].joined(separator: " · ")
        case .crawl:
            return [name, layerTitle(item.layer)].joined(separator: " · ")
        case .fullScreen:
            let look = item.fullScreen
            return [
                name, "Blur \(percent(look.blur))",
                "\(NoticeRulesControls.title(for: look.color.source)) \(percent(look.opacity))"
            ].joined(separator: " · ")
        case .system:
            return name
        }
    }

    private static func percent(_ fraction: Double) -> String {
        "\(Int((fraction * 100).rounded())) %"
    }

    static func screensTitle(_ screens: NoticeProfile.ScreenSelection) -> String {
        switch screens {
        case .main: "Main Screen"
        case .all: "All Screens"
        }
    }
}
