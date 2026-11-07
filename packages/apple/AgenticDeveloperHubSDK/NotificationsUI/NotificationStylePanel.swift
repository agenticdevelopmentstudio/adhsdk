import AppKit
import AgenticDeveloperHubSDK
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKMacOS
import AgenticDeveloperHubSDKNotifications

/// One urgency's topic under Notifications › Styles. Every urgency gets the
/// same set of properties — style, position, screens, layer, auto-dismiss and
/// Notification Center forwarding — written straight to that urgency's
/// profile in `NoticeSettings.routingRules`.
///
/// "Send test" sends a sample notice of this urgency through the host's
/// `NoticeActionHandler`, so it takes the same path a real one does.
@MainActor
final class NotificationStylePanel: ComposableSettings.SettingsPanelViewController {

    typealias Styles = NotificationStylesSettingsPanel

    let urgency: Notice.Urgency
    private weak var handler: NoticeActionHandler?
    private let controls: NoticeRulesControls

    /// The last sample sent, for tests.
    private(set) var lastSentTest: Notice?

    init(urgency: Notice.Urgency, handler: NoticeActionHandler, store: SettingsStore) {
        self.urgency = urgency
        self.handler = handler
        self.controls = NoticeRulesControls(store: store)
        let title = Styles.title(for: urgency)
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: title,
            icon: NSImage(systemSymbolName: Styles.symbol(for: urgency), accessibilityDescription: title)))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override var searchKeywords: [String] {
        ["toast", "crawl", "alert", "full screen", "position", "screens", "dismiss", "test"]
    }

    /// Sends a sample notice of this urgency through the host's real path.
    func sendTest() {
        let sample = Styles.sample(for: urgency)
        lastSentTest = sample
        handler?.sendTest(sample)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addGroup(profileGroup())
    }

    private func profileGroup() -> ComposableSettings.GroupView {
        let urgency = urgency
        let controls = controls
        let group = ComposableSettings.GroupView(withTitle: Styles.title(for: urgency))
        let profile = Styles.baseProfile(for: urgency, in: controls.rules)
        func edit(_ change: @escaping (inout NoticeProfile) -> Void) {
            controls.mutate { rules in
                var updated = Styles.baseProfile(for: urgency, in: rules)
                change(&updated)
                rules.profiles[urgency] = updated
            }
        }
        group.addSettingSubview(controls.row("Style", controls.popup(
            NoticeProfile.Style.allCases, selected: profile.style, title: Styles.styleTitle) { style in
                edit { $0.style = style }
            }))
        group.addSettingSubview(controls.row("Position", controls.popup(
            NoticeProfile.Position.allCases, selected: profile.position, title: Styles.positionTitle) { position in
                edit { $0.position = position }
            }))
        group.addSettingSubview(controls.row("Screens", controls.popup(
            NoticeProfile.ScreenSelection.allCases, selected: profile.screens,
            title: Styles.screensTitle) { screens in
                edit { $0.screens = screens }
            }))
        group.addSettingSubview(controls.row("Layer", controls.popup(
            NoticeProfile.Layer.allCases, selected: profile.layer,
            title: { $0 == .floating ? "Above other windows" : "With other windows" },
            onChange: { layer in edit { $0.layer = layer } })))
        let dismissals: [TimeInterval?] = [nil, 5, 8, 15, 30, 60]
        let current = dismissals.contains(profile.autoDismiss) ? profile.autoDismiss : nil
        group.addSettingSubview(controls.row("Dismiss after", controls.popup(
            dismissals, selected: current, title: { $0.map { "\(Int($0)) seconds" } ?? "Never" },
            onChange: { seconds in edit { $0.autoDismiss = seconds } })))
        group.addSettingSubview(controls.row(
            "Also post to Notification Center", controls.checkbox(profile.forwardToSystem) { isOn in
                edit { $0.forwardToSystem = isOn }
            }))
        group.addSettingSubview(ComposableSettings.ButtonView(
            viewModel: ComposableSettings.ButtonViewModel(title: "Send test") { [weak self] in
                self?.sendTest()
            },
            placement: .leading))
        return group
    }
}
