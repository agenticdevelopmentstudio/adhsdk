import AppKit
import AgenticDeveloperHubSDK
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKMacOS
import AgenticDeveloperHubSDKNotifications

/// One urgency's topic under Notifications › Styles. Every urgency gets the
/// same set of properties — style, position, layer and auto-dismiss — written
/// straight to that urgency's style set in `NoticeSettings.routingRules`.
/// Style, position and layer edit the set's first item; the rest of its items
/// are kept as they are.
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
        ["toast", "crawl", "alert", "full screen", "position", "dismiss", "test"]
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
        let set = Styles.baseStyle(for: urgency, in: controls.rules)
        let lead = set.items.first ?? NoticeProfile(style: .toast)
        func edit(_ change: @escaping (inout NoticeStyleSet) -> Void) {
            controls.mutate { rules in
                var updated = Styles.baseStyle(for: urgency, in: rules)
                change(&updated)
                rules.styles[urgency] = updated
            }
        }
        /// Position and layer edit the set's first item; with none, there is nothing to place.
        func editLead(_ change: @escaping (inout NoticeProfile) -> Void) {
            edit { set in
                guard !set.items.isEmpty else { return }
                change(&set.items[0])
            }
        }
        let styles: [NoticeProfile.Style?] = NoticeProfile.Style.allCases.map { $0 } + [nil]
        group.addSettingSubview(controls.row("Style", controls.popup(
            styles, selected: set.items.first?.style, title: { $0.map(Styles.styleTitle) ?? "Don't show" },
            onChange: { style in
                edit { set in
                    guard let style else {
                        set.items = []
                        return
                    }
                    if set.items.isEmpty {
                        set.items = [NoticeProfile(style: style)]
                    } else {
                        set.items[0] = NoticeProfile(style: style, layer: set.items[0].layer)
                    }
                }
            })))
        group.addSettingSubview(controls.row("Position", controls.popup(
            NoticeProfile.Position.allCases, selected: lead.position, title: Styles.positionTitle) { position in
                editLead { $0.position = position }
            }))
        group.addSettingSubview(controls.row("Layer", controls.popup(
            NoticeProfile.Layer.allCases, selected: lead.layer,
            title: { $0 == .floating ? "Above other windows" : "With other windows" },
            onChange: { layer in editLead { $0.layer = layer } })))
        let dismissals: [TimeInterval?] = [nil, 5, 8, 15, 30, 60]
        let current = dismissals.contains(set.autoDismiss) ? set.autoDismiss : nil
        group.addSettingSubview(controls.row("Dismiss after", controls.popup(
            dismissals, selected: current, title: { $0.map { "\(Int($0)) seconds" } ?? "Never" },
            onChange: { seconds in edit { $0.autoDismiss = seconds } })))
        group.addSettingSubview(ComposableSettings.ButtonView(
            viewModel: ComposableSettings.ButtonViewModel(title: "Send test") { [weak self] in
                self?.sendTest()
            },
            placement: .leading))
        return group
    }
}
