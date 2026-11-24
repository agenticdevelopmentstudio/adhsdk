import AppKit
import AgenticDeveloperHubSDK
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKMacOS
import AgenticDeveloperHubSDKNotifications

/// One urgency's topic under Notifications › Styles: the dismiss and snooze
/// settings every notification in the style shares, and the list of items the
/// style shows at once. Everything is written straight to that urgency's
/// style set in `NoticeSettings.routingRules`.
///
/// "Send test" sends a sample notice of this urgency through the host's
/// `NoticeActionHandler`, so it takes the same path a real one does.
@MainActor
final class NotificationStyleSetPanel: ComposableSettings.SettingsPanelViewController {

    typealias Styles = NotificationStylesSettingsPanel

    let urgency: Notice.Urgency
    private weak var handler: NoticeActionHandler?
    private let controls: NoticeRulesControls
    private let table = NotificationItemsTable()

    /// The last sample sent, for tests.
    private(set) var lastSentTest: Notice?
    /// The item editor currently open, if any.
    private(set) var activeEditor: NotificationItemEditor?

    private var dismissPopup = NSPopUpButton()
    private let secondsField = NSTextField()
    private let secondsRow = RevealableRow()
    /// The seconds the field shows when Custom… is chosen and nothing is stored yet.
    private var customSeconds: TimeInterval = 30
    private var snoozeBox = NSButton()
    private var optionBoxes: [SnoozeOption: NSButton] = [:]

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
        ["toast", "crawl", "alert", "full screen", "dismiss", "snooze", "item", "test"]
    }

    // MARK: Test hooks

    var itemsTable: NotificationItemsTable { table }
    var dismissAfterPopup: NSPopUpButton { dismissPopup }
    var customSecondsField: NSTextField { secondsField }
    var customSecondsRow: NSView { secondsRow }
    var canBeSnoozedCheckbox: NSButton { snoozeBox }
    var snoozeOptionCheckboxes: [SnoozeOption: NSButton] { optionBoxes }

    /// Sends a sample notice of this urgency through the host's real path.
    func sendTest() {
        let sample = Styles.sample(for: urgency)
        lastSentTest = sample
        handler?.sendTest(sample)
    }

    // MARK: Layout

    override func viewDidLoad() {
        super.viewDidLoad()
        addGroup(sharedGroup())
        let itemsGroup = itemsGroup()
        addGroup(itemsGroup)
        let test = ComposableSettings.GroupView(withHeaderView: NSView())
        test.addSettingSubview(ComposableSettings.ButtonView(
            viewModel: ComposableSettings.ButtonViewModel(title: "Send test") { [weak self] in
                self?.sendTest()
            },
            placement: .leading))
        addGroup(test)
        // The item list is the one thing that wants to grow, so the height the
        // panel leaves goes to it and never to a gap inside another card. It
        // pulls below `fitViewport`, so it can only fill the viewport, not
        // stretch the panel past it.
        let grow = table.scrollView.heightAnchor.constraint(equalToConstant: 100_000)
        grow.priority = Self.growPriority
        grow.isActive = true
        reloadItems()
    }

    /// The list's pull toward more height: just above the group stacks'
    /// hugging, which it has to beat, and far below `fitViewportPriority`.
    static let growPriority = NSLayoutConstraint.Priority(260)
    /// Keeps the panel at the viewport's height while its content fits; the
    /// content's required minimums still make it taller, and then it scrolls.
    /// Below `windowSizeStayPut`, so the panel never resizes the window, and
    /// far enough above `growPriority` that, once broken, the pull still
    /// cannot stretch the panel (close priorities trade off against each other).
    static let fitViewportPriority = NSLayoutConstraint.Priority(490)

    private weak var fittedClip: NSClipView?
    private var fitViewport: NSLayoutConstraint?

    override func viewWillLayout() {
        super.viewWillLayout()
        fitToViewport()
    }

    /// Bounds the panel to its scroll host's viewport. A `PanelScrollView`
    /// only says "at least the viewport", which leaves the list's pull
    /// nothing to stop at.
    private func fitToViewport() {
        let clip = view.enclosingScrollView?.contentView
        guard clip !== fittedClip else { return }
        fitViewport?.isActive = false
        fitViewport = nil
        fittedClip = clip
        guard let clip else { return }
        let fit = view.heightAnchor.constraint(equalTo: clip.heightAnchor)
        fit.priority = Self.fitViewportPriority
        fit.isActive = true
        fitViewport = fit
    }

    private var set: NoticeStyleSet { Styles.baseStyle(for: urgency, in: controls.rules) }

    private func edit(_ change: (inout NoticeStyleSet) -> Void) {
        let urgency = urgency
        controls.mutate { rules in
            var updated = Styles.baseStyle(for: urgency, in: rules)
            change(&updated)
            rules.styles[urgency] = updated
        }
    }

    private func sharedGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Every notification in this style")
        let current = set
        let stored = DismissAfterChoice(seconds: current.autoDismiss)
        if case .custom(let seconds) = stored { customSeconds = seconds }
        let choices = DismissAfterChoice.popupChoices(custom: customSeconds)
        dismissPopup = controls.popup(
            choices, selected: choices.first { $0.isSameItem(as: stored) } ?? stored,
            title: \.title,
            onChange: { [weak self] choice in self?.dismissChosen(choice) })
        group.addSettingSubview(controls.row("Dismiss after", dismissPopup))

        secondsField.stringValue = DismissAfterChoice.secondsText(customSeconds)
        secondsField.alignment = .right
        secondsField.widthAnchor.constraint(equalToConstant: 70).isActive = true
        secondsField.target = self
        secondsField.action = #selector(secondsCommitted)
        secondsField.setAccessibilityLabel("Seconds")
        secondsRow.setContent(controls.row("Seconds", secondsField))
        secondsRow.isHidden = !isCustomChosen
        group.addSettingSubview(secondsRow)

        snoozeBox = controls.checkbox(current.snooze.isEnabled) { [weak self] isOn in
            self?.edit { $0.snooze.isEnabled = isOn }
            self?.syncSnoozeOptions()
        }
        group.addSettingSubview(controls.row("Can be snoozed", snoozeBox))
        for option in SnoozeOption.allCases {
            let box = controls.checkbox(current.snooze.options.contains(option)) { [weak self] isOn in
                self?.edit { set in
                    if isOn {
                        if !set.snooze.options.contains(option) { set.snooze.options.append(option) }
                    } else {
                        set.snooze.options.removeAll { $0 == option }
                    }
                }
            }
            optionBoxes[option] = box
            group.addSettingSubview(controls.row(option.title, box))
        }
        syncSnoozeOptions()
        return group
    }

    private var isCustomChosen: Bool {
        dismissPopup.indexOfSelectedItem == DismissAfterChoice.presets.count
    }

    private func dismissChosen(_ choice: DismissAfterChoice) {
        switch choice {
        case .preset(let seconds):
            secondsRow.isHidden = true
            secondsField.stringValue = DismissAfterChoice.secondsText(customSeconds)
            edit { $0.autoDismiss = seconds }
        case .custom:
            // Revealing the field stores nothing: only a valid number does.
            secondsRow.isHidden = false
        }
    }

    @objc private func secondsCommitted() {
        guard let seconds = DismissAfterChoice.customSeconds(from: secondsField.stringValue) else {
            secondsField.stringValue = DismissAfterChoice.secondsText(customSeconds)
            return
        }
        customSeconds = seconds
        secondsField.stringValue = DismissAfterChoice.secondsText(seconds)
        edit { $0.autoDismiss = seconds }
    }

    private func syncSnoozeOptions() {
        let enabled = snoozeBox.state == .on
        for box in optionBoxes.values { box.isEnabled = enabled }
    }

    private func itemsGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Notifications")
        table.install(in: group.cardView)
        table.onAdd = { [weak self] in self?.addItem() }
        table.onRemove = { [weak self] rows in self?.removeItems(at: rows) }
        table.onEdit = { [weak self] row in self?.openEditor(row: row) }
        return group
    }

    private func reloadItems() {
        table.setItems(set.items)
    }

    // MARK: Items

    private func addItem() {
        var index = 0
        edit { set in
            set.items.append(NoticeProfile(style: .toast, position: .bottomRight))
            index = set.items.count - 1
        }
        reloadItems()
        openEditor(row: index)
    }

    private func removeItems(at rows: IndexSet) {
        edit { set in
            for row in rows.sorted(by: >) where set.items.indices.contains(row) {
                set.items.remove(at: row)
            }
        }
        reloadItems()
    }

    private func openEditor(row: Int) {
        guard set.items.indices.contains(row), let window = view.window else { return }
        let opened = set.items[row]
        let editor = NotificationItemEditor(
            item: opened, store: controls.store,
            onDone: { [weak self] item in
                self?.edit { set in
                    // Overwrite only the row the editor opened; if the list
                    // changed under the sheet, keep the edit as a new item.
                    if set.items.indices.contains(row), set.items[row] == opened {
                        set.items[row] = item
                    } else {
                        set.items.append(item)
                    }
                }
                self?.reloadItems()
                self?.activeEditor = nil
            },
            onCancel: { [weak self] in self?.activeEditor = nil })
        activeEditor = editor
        editor.present(on: window)
    }
}

/// A settings row that hides itself, and tells its card to close up.
@MainActor
final class RevealableRow: NSView, ComposableSettings.SelfHidingSettingsView {

    var onVisibilityChange: (() -> Void)?

    override var isHidden: Bool {
        didSet { if isHidden != oldValue { onVisibilityChange?() } }
    }

    func setContent(_ content: NSView) {
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: topAnchor),
            content.bottomAnchor.constraint(equalTo: bottomAnchor),
            content.leadingAnchor.constraint(equalTo: leadingAnchor),
            content.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
}
