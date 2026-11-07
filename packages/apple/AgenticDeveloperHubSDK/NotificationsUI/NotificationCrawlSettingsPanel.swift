import AppKit
import AgenticDeveloperHubSDK
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKMacOS
import AgenticDeveloperHubSDKNotifications

/// Notifications › Crawl: where the crawl runs and how it looks and moves.
/// There is one crawl, so these are global, written to
/// `NoticeRoutingRules.crawl`.
@MainActor
final class NotificationCrawlSettingsPanel: ComposableSettings.SettingsPanelViewController {

    private let controls: NoticeRulesControls

    init(store: SettingsStore) {
        self.controls = NoticeRulesControls(store: store)
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "Crawl",
            icon: NSImage(systemSymbolName: "arrow.left.and.right", accessibilityDescription: "Crawl")))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override var searchKeywords: [String] {
        ["crawl", "ticker", "edge", "speed", "background", "direction", "text size", "transparency"]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addGroup(placementGroup())
        addGroup(backgroundGroup())
        addGroup(motionGroup())
        addGroup(textGroup())
    }

    private func change(_ change: @escaping (inout CrawlSettings) -> Void) {
        controls.mutate { change(&$0.crawl) }
    }

    private static func percent(_ value: Double) -> String { "\(Int(value.rounded())) %" }

    private func placementGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Placement")
        group.addSettingSubview(controls.row("Edge", controls.popup(
            CrawlSettings.Edge.allCases, selected: controls.rules.crawl.edge,
            title: { $0 == .top ? "Top" : "Bottom" },
            onChange: { [weak self] edge in self?.change { $0.edge = edge } })))
        return group
    }

    private func backgroundGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Background")
        let controls = controls
        group.addSettingSubview(controls.row("Show background", controls.checkbox(
            controls.rules.crawl.showsBackground) { [weak self] isOn in
                self?.change { $0.showsBackground = isOn }
            }))
        group.addSettingSubview(controls.colorChoice(
            title: "Background color", get: { controls.rules.crawl.background },
            set: { [weak self] color in self?.change { $0.background = color } }))
        group.addSettingSubview(controls.slider(
            title: "Background transparency", range: 0...100, format: Self.percent,
            get: { (1 - controls.rules.crawl.backgroundOpacity) * 100 },
            set: { [weak self] value in self?.change { $0.backgroundOpacity = 1 - value / 100 } }))
        return group
    }

    private func motionGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Motion")
        let controls = controls
        let speed = CrawlSettings.speedRange
        group.addSettingSubview(controls.slider(
            title: "Speed", range: speed,
            format: { "\(Int($0.rounded())) pt/s" },
            get: { controls.rules.crawl.speed },
            set: { [weak self] value in self?.change { $0.speed = value } }))
        group.addSettingSubview(controls.row("Direction", controls.popup(
            [false, true], selected: controls.rules.crawl.leftToRight,
            title: { $0 ? "Left to Right" : "Right to Left" },
            onChange: { [weak self] leftToRight in self?.change { $0.leftToRight = leftToRight } })))
        return group
    }

    private func textGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Text")
        let controls = controls
        group.addSettingSubview(controls.slider(
            title: "Text size", range: CrawlSettings.textSizeRange,
            format: { "\(Int($0.rounded())) pt" },
            get: { controls.rules.crawl.textSize },
            set: { [weak self] value in self?.change { $0.textSize = value } }))
        group.addSettingSubview(controls.slider(
            title: "Item transparency", range: 0...80, format: Self.percent,
            get: { (1 - controls.rules.crawl.itemOpacity) * 100 },
            set: { [weak self] value in self?.change { $0.itemOpacity = 1 - value / 100 } }))
        return group
    }
}
