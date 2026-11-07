import AppKit
import AgenticDeveloperHubSDK
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKMacOS
import AgenticDeveloperHubSDKUI
import AgenticDeveloperHubSDKNotifications

/// Notifications › Overrides: rules matched by source, category or urgency
/// that are tried before a notice's urgency style.
@MainActor
final class NotificationOverridesSettingsPanel: ComposableSettings.SettingsPanelViewController {

    typealias Styles = NotificationStylesSettingsPanel

    private let controls: NoticeRulesControls
    private let overrideList = NSStackView()
    private let newOverrideSource = ThemedTextField()
    private let newOverrideCategory = ThemedTextField()
    /// The target popup of the new-override row: "Use <Urgency> style" for each urgency, then "Don't show".
    private(set) var targetPopup = NSPopUpButton()
    private var newOverrideUrgency: Notice.Urgency?
    private var newOverrideTarget: NoticeRoutingRules.Override.Target = .style(.fyi)

    init(store: SettingsStore) {
        self.controls = NoticeRulesControls(store: store)
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "Overrides",
            icon: NSImage(systemSymbolName: "arrow.triangle.branch", accessibilityDescription: "Overrides")))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override var searchKeywords: [String] { ["override", "source", "category", "rule"] }

    override func viewDidLoad() {
        super.viewDidLoad()
        addGroup(overridesGroup())
    }

    private func overridesGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Overrides")
        overrideList.orientation = .vertical
        overrideList.alignment = .leading
        overrideList.spacing = 6
        overrideList.translatesAutoresizingMaskIntoConstraints = false
        group.addSettingSubview(overrideList)
        rebuildOverrideList()

        newOverrideSource.placeholderString = "Source"
        newOverrideCategory.placeholderString = "Category"
        for field in [newOverrideSource, newOverrideCategory] {
            field.widthAnchor.constraint(equalToConstant: 110).isActive = true
        }
        let urgencies: [Notice.Urgency?] = [nil] + Notice.Urgency.allCases.map { $0 }
        let urgencyPopup = controls.popup(
            urgencies, selected: nil, title: { $0.map(Styles.title(for:)) ?? "Any urgency" },
            onChange: { [weak self] urgency in self?.newOverrideUrgency = urgency })
        let targets = Notice.Urgency.allCases.map(NoticeRoutingRules.Override.Target.style) + [.hide]
        let stylePopup = controls.popup(
            targets, selected: .style(.fyi),
            title: { $0 == .hide ? Styles.targetTitle($0) : "Use " + Styles.targetTitle($0) },
            onChange: { [weak self] target in self?.newOverrideTarget = target })
        targetPopup = stylePopup
        let add = controls.button("Add") { [weak self] in self?.addOverride() }
        group.addSettingSubview(NSView.makeSettingsRow([
            newOverrideSource, newOverrideCategory, urgencyPopup, stylePopup, add
        ]))
        return group
    }

    private func rebuildOverrideList() {
        for view in overrideList.arrangedSubviews {
            overrideList.removeView(view)
        }
        let overrides = controls.rules.overrides
        if overrides.isEmpty {
            let empty = ComposableSettings.makeValueLabel("No overrides. Every notice uses its urgency's style.")
            overrideList.addArrangedSubview(empty)
            return
        }
        for (index, override) in overrides.enumerated() {
            let label = ComposableSettings.makeRowLabel(Styles.describe(override))
            let remove = controls.button("Remove") { [weak self] in
                self?.controls.mutate { rules in
                    guard rules.overrides.indices.contains(index) else { return }
                    rules.overrides.remove(at: index)
                }
                self?.rebuildOverrideList()
            }
            let line = NSView.makeSettingsRow([label, remove])
            overrideList.addArrangedSubview(line)
            line.widthAnchor.constraint(equalTo: overrideList.widthAnchor).isActive = true
        }
    }

    private func addOverride() {
        let source = newOverrideSource.stringValue.trimmingCharacters(in: .whitespaces)
        let category = newOverrideCategory.stringValue.trimmingCharacters(in: .whitespaces)
        let urgency = newOverrideUrgency
        let target = newOverrideTarget
        guard !source.isEmpty || !category.isEmpty || urgency != nil else { return }
        controls.mutate { rules in
            rules.overrides.append(.init(
                source: source.isEmpty ? nil : source,
                category: category.isEmpty ? nil : category,
                urgency: urgency,
                target: target))
        }
        newOverrideSource.stringValue = ""
        newOverrideCategory.stringValue = ""
        rebuildOverrideList()
    }
}
