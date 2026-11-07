import AppKit
import AgenticDeveloperHubSDK
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKMacOS
import AgenticDeveloperHubSDKUI
import AgenticDeveloperHubSDKNotifications

/// The controls every Notifications settings topic builds its rows from, and
/// the one path they all write `NoticeSettings.routingRules` through. Owned
/// by each topic panel (composition), so the topics share their editing
/// without sharing a base class. Public so a host's own panel (Rooster's
/// General) can build its rows the same way.
@MainActor
public final class NoticeRulesControls {

    public let store: SettingsStore
    /// Targets for the controls; a control's target is weak.
    private var targets: [ClosureMenuItemTarget] = []

    public init(store: SettingsStore) {
        self.store = store
    }

    public var rules: NoticeRoutingRules { store.get(NoticeSettings.routingRules) }

    public func mutate(_ change: (inout NoticeRoutingRules) -> Void) {
        var rules = rules
        change(&rules)
        store.set(rules, for: NoticeSettings.routingRules)
    }

    public func row(_ title: String, _ control: NSView) -> NSView {
        NSView.makeSettingsRow([ComposableSettings.makeRowLabel(title), control])
    }

    public func popup<Value: Equatable>(
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

    public func checkbox(_ isOn: Bool, onChange: @escaping (Bool) -> Void) -> NSButton {
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

    public func button(_ title: String, action: @escaping () -> Void) -> NSButton {
        let target = ClosureMenuItemTarget(action: action)
        targets.append(target)
        return NSButton(
            title: title, target: target, action: #selector(ClosureMenuItemTarget.performMenuAction(_:)))
    }

    /// A row: the title, a slider over `range` that fills the gap, and its
    /// current value, drawn by `format`. `set` is told every change as the
    /// slider moves. The caller maps units (a transparency shown as 0–100 %
    /// but stored as an opacity) in `get` and `set`.
    public func slider(
        title: String,
        range: ClosedRange<Double>,
        format: @escaping (Double) -> String = { "\(Int($0.rounded()))" },
        get: () -> Double,
        set: @escaping (Double) -> Void
    ) -> NSView {
        let slider = NSSlider(
            value: get(), minValue: range.lowerBound, maxValue: range.upperBound, target: nil, action: nil)
        slider.isContinuous = true
        // Below the row spacer's hugging, so the slider takes the width left over.
        slider.setContentHuggingPriority(.init(1), for: .horizontal)
        slider.widthAnchor.constraint(greaterThanOrEqualToConstant: 120).isActive = true
        let value = ComposableSettings.makeValueLabel(format(slider.doubleValue), monospacedDigits: true)
        value.alignment = .right
        value.widthAnchor.constraint(greaterThanOrEqualToConstant: 64).isActive = true
        let target = ClosureMenuItemTarget(action: { [weak slider, weak value] in
            guard let slider else { return }
            value?.stringValue = format(slider.doubleValue)
            set(slider.doubleValue)
        })
        targets.append(target)
        slider.target = target
        slider.action = #selector(ClosureMenuItemTarget.performMenuAction(_:))
        return NSView.makeSettingsRow([ComposableSettings.makeRowLabel(title), slider, value])
    }

    /// A row: the title, a popup of System, Theme and Custom, and an
    /// `NSColorWell` that is live only for Custom. Picking Custom again keeps
    /// the last custom color the well showed.
    public func colorChoice(
        title: String,
        get: () -> NoticeColor,
        set: @escaping (NoticeColor) -> Void
    ) -> NSView {
        let current = get()
        let well = NSColorWell()
        // System and Theme carry no color of their own; seed the well with a
        // visible neutral gray so switching to Custom starts from something.
        well.color = current.source == .custom
            ? NSColor(srgbRed: current.red, green: current.green, blue: current.blue, alpha: 1)
            : NSColor(srgbRed: 0.5, green: 0.5, blue: 0.5, alpha: 1)
        well.isEnabled = current.source == .custom
        well.widthAnchor.constraint(equalToConstant: 44).isActive = true
        func custom() -> NoticeColor {
            let rgb = well.color.usingColorSpace(.sRGB) ?? well.color
            return .custom(red: rgb.redComponent, green: rgb.greenComponent, blue: rgb.blueComponent)
        }
        let sourcePopup = popup(
            NoticeColor.Source.allCases, selected: current.source,
            title: { Self.title(for: $0) },
            onChange: { [weak well] source in
                well?.isEnabled = source == .custom
                switch source {
                case .system: set(.system)
                case .theme: set(.theme)
                case .custom: set(custom())
                }
            })
        let target = ClosureMenuItemTarget(action: { set(custom()) })
        targets.append(target)
        well.target = target
        well.action = #selector(ClosureMenuItemTarget.performMenuAction(_:))
        return NSView.makeSettingsRow([ComposableSettings.makeRowLabel(title), sourcePopup, well])
    }

    /// The popup's title for a color source.
    public static func title(for source: NoticeColor.Source) -> String {
        switch source {
        case .system: "System"
        case .theme: "Theme"
        case .custom: "Custom"
        }
    }
}
