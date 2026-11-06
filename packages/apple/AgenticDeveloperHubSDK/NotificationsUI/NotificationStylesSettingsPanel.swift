import AppKit
import AgenticDeveloperHubSDK
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKMacOS
import AgenticDeveloperHubSDKUI
import AgenticDeveloperHubSDKNotifications

/// "Notification Styles": how each urgency is presented, the overrides tried
/// before them, the toast stack, escalation and flood thresholds, screen
/// sharing, hotkeys and the crawl's direction. Every edit is written straight
/// to `NoticeSettings.routingRules`; a host's presentation center reads that
/// setting, so changes apply to the next notice.
///
/// Each urgency has a "Send test" button that sends a sample notice through
/// the host's `NoticeActionHandler`, so it takes the same path a real one does.
@MainActor
public final class NotificationStylesSettingsPanel: ComposableSettings.SettingsPanelViewController {

    private weak var handler: NoticeActionHandler?
    private let store: SettingsStore
    /// Targets for the panel's controls; a control's target is weak.
    private var targets: [ClosureMenuItemTarget] = []
    private let overrideList = NSStackView()
    private let newOverrideSource = ThemedTextField()
    private let newOverrideCategory = ThemedTextField()
    private var newOverrideUrgency: Notice.Urgency?
    private var newOverrideStyle: NoticeProfile.Style = .toast

    /// The last sample sent, for tests.
    private(set) var lastSentTest: Notice?

    public init(handler: NoticeActionHandler, store: SettingsStore = UserSettings.shared) {
        self.handler = handler
        self.store = store
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "Notification Styles",
            icon: NSImage(systemSymbolName: "bell.badge", accessibilityDescription: "Notification Styles")))
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }

    public override var searchKeywords: [String] {
        ["notifications", "toast", "crawl", "alert", "full screen", "hotkeys", "snooze", "escalation", "flood"]
    }

    private var rules: NoticeRoutingRules { store.get(NoticeSettings.routingRules) }

    private func mutate(_ change: (inout NoticeRoutingRules) -> Void) {
        var rules = rules
        change(&rules)
        store.set(rules, for: NoticeSettings.routingRules)
    }

    // MARK: Test notices

    /// Sends a sample notice of `urgency` through the host's real path.
    func sendTest(_ urgency: Notice.Urgency) {
        let sample = Self.sample(for: urgency)
        lastSentTest = sample
        handler?.sendTest(sample)
    }

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

    // MARK: Building

    public override func viewDidLoad() {
        super.viewDidLoad()
        for urgency in Notice.Urgency.allCases {
            addGroup(profileGroup(for: urgency))
        }
        addGroup(overridesGroup())
        addGroup(thresholdsGroup())
        addGroup(privacyGroup())
        let focus = ComposableSettings.GroupView(withTitle: "Focus")
        focus.addSettingSubview(ComposableSettings.ValueRowView(
            title: "Hold notices during Focus", value: "Unavailable — needs the Focus Status entitlement"))
        addGroup(focus)
    }

    private func profileGroup(for urgency: Notice.Urgency) -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: Self.title(for: urgency))
        let profile = rules.profile(for: Self.sample(for: urgency))
        func edit(_ change: @escaping (inout NoticeProfile) -> Void) {
            mutate { rules in
                var updated = rules.profiles[urgency] ?? rules.profile(for: Self.sample(for: urgency))
                change(&updated)
                rules.profiles[urgency] = updated
            }
        }
        group.addSettingSubview(row("Style", popup(
            NoticeProfile.Style.allCases, selected: profile.style, title: Self.styleTitle) { style in
                edit { $0.style = style }
            }))
        group.addSettingSubview(row("Position", popup(
            NoticeProfile.Position.allCases, selected: profile.position, title: Self.positionTitle) { position in
                edit { $0.position = position }
            }))
        group.addSettingSubview(row("Screens", popup(
            NoticeProfile.ScreenSelection.allCases, selected: profile.screens, title: Self.screensTitle) { screens in
                edit { $0.screens = screens }
            }))
        group.addSettingSubview(row("Layer", popup(
            NoticeProfile.Layer.allCases, selected: profile.layer,
            title: { $0 == .floating ? "Above other windows" : "With other windows" },
            onChange: { layer in edit { $0.layer = layer } })))
        let dismissals: [TimeInterval?] = [nil, 5, 8, 15, 30, 60]
        let current = dismissals.contains(profile.autoDismiss) ? profile.autoDismiss : nil
        group.addSettingSubview(row("Dismiss after", popup(
            dismissals, selected: current, title: { $0.map { "\(Int($0)) seconds" } ?? "Never" },
            onChange: { seconds in edit { $0.autoDismiss = seconds } })))
        group.addSettingSubview(row("Also post to Notification Center", checkbox(profile.forwardToSystem) { isOn in
            edit { $0.forwardToSystem = isOn }
        }))
        group.addSettingSubview(ComposableSettings.ButtonView(
            viewModel: ComposableSettings.ButtonViewModel(title: "Send test") { [weak self] in
                self?.sendTest(urgency)
            },
            placement: .leading))
        return group
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
        let urgencyPopup = popup(
            urgencies, selected: nil, title: { $0.map(Self.title(for:)) ?? "Any urgency" },
            onChange: { [weak self] urgency in self?.newOverrideUrgency = urgency })
        let stylePopup = popup(
            NoticeProfile.Style.allCases, selected: .toast, title: Self.styleTitle
        ) { [weak self] style in
            self?.newOverrideStyle = style
        }
        let add = button("Add") { [weak self] in self?.addOverride() }
        group.addSettingSubview(NSView.makeRow([
            newOverrideSource, newOverrideCategory, urgencyPopup, stylePopup, add
        ]))
        return group
    }

    private func rebuildOverrideList() {
        for view in overrideList.arrangedSubviews {
            overrideList.removeView(view)
        }
        let overrides = rules.overrides
        if overrides.isEmpty {
            let empty = ComposableSettings.makeValueLabel("No overrides. Every notice uses its urgency's style.")
            overrideList.addArrangedSubview(empty)
            return
        }
        for (index, override) in overrides.enumerated() {
            let label = ComposableSettings.makeRowLabel(Self.describe(override))
            let remove = button("Remove") { [weak self] in
                self?.mutate { rules in
                    guard rules.overrides.indices.contains(index) else { return }
                    rules.overrides.remove(at: index)
                }
                self?.rebuildOverrideList()
            }
            let line = NSView.makeRow([label, remove])
            overrideList.addArrangedSubview(line)
            line.widthAnchor.constraint(equalTo: overrideList.widthAnchor).isActive = true
        }
    }

    private func addOverride() {
        let source = newOverrideSource.stringValue.trimmingCharacters(in: .whitespaces)
        let category = newOverrideCategory.stringValue.trimmingCharacters(in: .whitespaces)
        let urgency = newOverrideUrgency
        let style = newOverrideStyle
        guard !source.isEmpty || !category.isEmpty || urgency != nil else { return }
        mutate { rules in
            var profile = rules.profile(for: Self.sample(for: urgency ?? .fyi))
            profile.style = style
            rules.overrides.append(.init(
                source: source.isEmpty ? nil : source,
                category: category.isEmpty ? nil : category,
                urgency: urgency,
                profile: profile))
        }
        newOverrideSource.stringValue = ""
        newOverrideCategory.stringValue = ""
        rebuildOverrideList()
    }

    static func describe(_ override: NoticeRoutingRules.Override) -> String {
        var match: [String] = []
        if let source = override.source { match.append("source \(source)") }
        if let category = override.category { match.append("category \(category)") }
        if let urgency = override.urgency { match.append(title(for: urgency)) }
        return "\(match.joined(separator: ", ")) → \(styleTitle(override.profile.style))"
    }

    private func thresholdsGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Stacks, escalation and floods")
        let rules = rules
        group.addSettingSubview(row("Toasts shown per stack", popup(
            Array(1...8), selected: rules.toastStackLimit, title: { "\($0)" },
            onChange: { [weak self] limit in self?.mutate { $0.toastStackLimit = limit } })))
        let waits: [TimeInterval] = [0, 300, 900, 1800, 3600]
        group.addSettingSubview(row("Raise Soon to Now after", popup(
            Self.including(rules.escalation.soonToNowAfter, in: waits),
            selected: rules.escalation.soonToNowAfter, title: Self.waitTitle) { [weak self] wait in
                self?.mutate { $0.escalation.soonToNowAfter = wait }
            }))
        group.addSettingSubview(row("Raise Eventually to Soon after", popup(
            Self.including(rules.escalation.eventuallyToSoonAfter, in: waits),
            selected: rules.escalation.eventuallyToSoonAfter, title: Self.waitTitle) { [weak self] wait in
                self?.mutate { $0.escalation.eventuallyToSoonAfter = wait }
            }))
        group.addSettingSubview(row("Fold a source after", popup(
            Self.including(rules.flood.threshold, in: [3, 5, 10, 20]),
            selected: rules.flood.threshold, title: { "\($0) notices" },
            onChange: { [weak self] threshold in self?.mutate { $0.flood.threshold = threshold } })))
        group.addSettingSubview(row("Within", popup(
            Self.including(rules.flood.window, in: [5, 10, 30, 60]),
            selected: rules.flood.window, title: { "\(Int($0)) seconds" },
            onChange: { [weak self] window in self?.mutate { $0.flood.window = window } })))
        return group
    }

    private func privacyGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Sharing and keyboard")
        let rules = rules
        let hide = checkbox(rules.hideFromScreenSharing) { [weak self] isOn in
            self?.mutate { $0.hideFromScreenSharing = isOn }
        }
        group.addSettingSubview(row("Hide from screen sharing", hide))
        let hotkeys = checkbox(rules.hotkeysEnabled) { [weak self] isOn in
            self?.mutate { $0.hotkeysEnabled = isOn }
        }
        group.addSettingSubview(row("Global hotkeys (⌃⌥⌘ Return, Delete, S, H)", hotkeys))
        group.addSettingSubview(row("Crawl direction", popup(
            [false, true], selected: rules.crawlLeftToRight,
            title: { $0 ? "Left to right" : "Right to left" },
            onChange: { [weak self] leftToRight in self?.mutate { $0.crawlLeftToRight = leftToRight } })))
        return group
    }

    // MARK: Controls

    private func row(_ title: String, _ control: NSView) -> NSView {
        NSView.makeRow([ComposableSettings.makeRowLabel(title), control])
    }

    private func popup<Value: Equatable>(
        _ values: [Value], selected: Value, title: (Value) -> String,
        onChange: @escaping (Value) -> Void
    ) -> NSPopUpButton {
        let popup = NSPopUpButton(frame: .zero, pullsDown: false)
        popup.autoenablesItems = false
        popup.addItems(withTitles: values.map(title))
        popup.selectItem(at: values.firstIndex(of: selected) ?? 0)
        let target = ClosureMenuItemTarget(action: { [weak popup] in
            guard let popup, values.indices.contains(popup.indexOfSelectedItem) else { return }
            onChange(values[popup.indexOfSelectedItem])
        })
        targets.append(target)
        popup.target = target
        popup.action = #selector(ClosureMenuItemTarget.performMenuAction(_:))
        return popup
    }

    private func checkbox(_ isOn: Bool, onChange: @escaping (Bool) -> Void) -> NSButton {
        let box = NSButton(checkboxWithTitle: "", target: nil, action: nil)
        box.state = isOn ? .on : .off
        let target = ClosureMenuItemTarget(action: { [weak box] in
            guard let box else { return }
            onChange(box.state == .on)
        })
        targets.append(target)
        box.target = target
        box.action = #selector(ClosureMenuItemTarget.performMenuAction(_:))
        return box
    }

    private func button(_ title: String, action: @escaping () -> Void) -> NSButton {
        let target = ClosureMenuItemTarget(action: action)
        targets.append(target)
        return NSButton(
            title: title, target: target, action: #selector(ClosureMenuItemTarget.performMenuAction(_:)))
    }

    // MARK: Titles

    private static func including<Value: Comparable>(_ value: Value, in values: [Value]) -> [Value] {
        values.contains(value) ? values : (values + [value]).sorted()
    }

    private static func waitTitle(_ seconds: TimeInterval) -> String {
        guard seconds > 0 else { return "Never" }
        return seconds >= 3600 && seconds.truncatingRemainder(dividingBy: 3600) == 0
            ? "\(Int(seconds / 3600)) hour\(seconds == 3600 ? "" : "s")"
            : "\(Int(seconds / 60)) minutes"
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
