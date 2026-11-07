import AppKit
import AgenticDeveloperHubSDK
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKMacOS
import AgenticDeveloperHubSDKUI
import AgenticDeveloperHubSDKNotifications

/// The controls every Notifications settings topic builds its rows from, and
/// the one path they all write `NoticeSettings.routingRules` through. Owned
/// by each topic panel (composition), so the topics share their editing
/// without sharing a base class.
@MainActor
final class NoticeRulesControls {

    let store: SettingsStore
    /// Targets for the controls; a control's target is weak.
    private var targets: [ClosureMenuItemTarget] = []

    init(store: SettingsStore) {
        self.store = store
    }

    var rules: NoticeRoutingRules { store.get(NoticeSettings.routingRules) }

    func mutate(_ change: (inout NoticeRoutingRules) -> Void) {
        var rules = rules
        change(&rules)
        store.set(rules, for: NoticeSettings.routingRules)
    }

    func row(_ title: String, _ control: NSView) -> NSView {
        NSView.makeSettingsRow([ComposableSettings.makeRowLabel(title), control])
    }

    func popup<Value: Equatable>(
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

    func checkbox(_ isOn: Bool, onChange: @escaping (Bool) -> Void) -> NSButton {
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

    func button(_ title: String, action: @escaping () -> Void) -> NSButton {
        let target = ClosureMenuItemTarget(action: action)
        targets.append(target)
        return NSButton(
            title: title, target: target, action: #selector(ClosureMenuItemTarget.performMenuAction(_:)))
    }
}
