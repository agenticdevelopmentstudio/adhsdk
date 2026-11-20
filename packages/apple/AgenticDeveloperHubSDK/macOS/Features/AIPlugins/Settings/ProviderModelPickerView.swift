import AppKit
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreMacOS
import AIPluginKit

/// The shared "which LLM runs this feature" control: a provider popup row above
/// an ``AIModelPickerControl`` row.
///
/// ```
/// Provider [ Ollama          ⌄ ]
/// AI Model ⌄ : llama3.2:3b
/// ```
///
/// It works over a ``ProviderRegistrySource`` (the app's own configurations or
/// the daemon's list) and edits only the settings the caller binds it to: the
/// provider selection, and the model setting for a provider. Pushing them
/// anywhere is the host's business.
///
/// Rules:
/// - Changing the provider sets the model setting to `""`, which means the new
///   provider's default model, or none for a sentinel.
/// - The model row shows the stored model when non-empty, else the provider
///   config's default model, else ``AIModelPickerControl/chooseModelText``.
/// - With a sentinel (a leading choice) selected, the model row is disabled.
@MainActor
public final class ProviderModelPickerView: NSView, SettingsViewProtocol {

    /// A non-configuration entry that leads the provider popup. `value` is what
    /// gets written to the selection setting, so the host's sentinel vocabulary
    /// ("" = default, "claude-cli" = the zero-config CLI path) stays the host's.
    public struct LeadingChoice: Sendable, Equatable {
        public let label: String
        public let value: String
        public init(label: String, value: String) {
            self.label = label
            self.value = value
        }
    }

    private let source: any ProviderRegistrySource
    private let selectedSetting: UserSetting<String>
    private let leadingChoices: [LeadingChoice]
    private let modelSetting: @MainActor (UUID?) -> UserSetting<String>?

    private let providerLabel: NSTextField
    private let providerPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private var modelControl: AIModelPickerControl!
    private var selectionObserver: UserSettingObserver<String>?
    private var modelObserver: UserSettingObserver<String>?
    public private(set) var choices: [(label: String, value: String)] = []

    /// - Parameters:
    ///   - source: the provider registry to list.
    ///   - selectedSetting: holds the chosen provider (a configuration UUID
    ///     string, or one of `leadingChoices`' values).
    ///   - leadingChoices: sentinel entries shown above the configured providers.
    ///   - providerLabel: the provider row's label.
    ///   - modelLabel: the model row's label.
    ///   - modelSetting: the setting holding the model for a provider; called
    ///     with nil for a sentinel. One shared setting (summaries, oversight)
    ///     ignores the id; per-config settings (the Partner) return nil for a
    ///     sentinel.
    public init(
        source: any ProviderRegistrySource,
        selectedSetting: UserSetting<String>,
        leadingChoices: [LeadingChoice] = [],
        providerLabel: String = "Provider",
        modelLabel: String = "AI Model",
        modelSetting: @escaping @MainActor (UUID?) -> UserSetting<String>?
    ) {
        self.source = source
        self.selectedSetting = selectedSetting
        self.leadingChoices = leadingChoices
        self.modelSetting = modelSetting
        self.providerLabel = NSTextField(labelWithString: providerLabel)
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        modelControl = AIModelPickerControl(
            label: modelLabel,
            displayName: { [weak self] in self?.displayedModel },
            context: { [weak self] in self?.chooserContext },
            onChoose: { [weak self] model in self?.choose(model) })
        buildLayout()

        providerPopup.target = self
        providerPopup.action = #selector(popupChanged)
        NotificationCenter.default.addObserver(
            self, selector: #selector(menuWillOpen), name: NSPopUpButton.willPopUpNotification, object: providerPopup)
        source.onChange = { [weak self] in self?.rebuildMenu() }
        selectionObserver = UserSettingObserver(selectedSetting) { [weak self] _ in
            self?.syncSelection()
            self?.observeModelSetting()
            self?.modelControl.invalidateContext()
            self?.modelControl.refresh()
        }
        rebuildMenu()
        observeModelSetting()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Span the host stack's width, the way `GroupView` does; not required, so a
    /// host that pins its own width always wins.
    public override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        guard let parent = superview else { return }
        let fullWidth = widthAnchor.constraint(equalTo: parent.widthAnchor)
        fullWidth.priority = .required - 1
        fullWidth.isActive = true
    }

    // MARK: - Testable surface

    /// The provider popup, for hosts' tests.
    public var providerPopUpButton: NSPopUpButton { providerPopup }
    /// The model row.
    public var modelPicker: AIModelPickerControl { modelControl }

    /// Sentinels first, in the caller's order, then the source's providers in
    /// its order.
    public nonisolated static func menuChoices(
        leading: [LeadingChoice], providers: [ProviderRegistryEntry]
    ) -> [(label: String, value: String)] {
        leading.map { ($0.label, $0.value) } + providers.map { ($0.name, $0.id.uuidString) }
    }

    /// Test seam for a user pick.
    func selectChoice(at index: Int) {
        providerPopup.selectItem(at: index)
        popupChanged()
    }

    /// Re-reads the providers and the model row.
    public func refresh() {
        source.reload()
        rebuildMenu()
    }

    // MARK: - State

    /// The selected provider's id, nil for a sentinel or an unknown value.
    private var selectedProviderID: UUID? {
        guard let id = UUID(uuidString: selectedSetting.value),
              source.providers.contains(where: { $0.id == id }) else { return nil }
        return id
    }

    private var storedModel: String {
        modelSetting(selectedProviderID)?.value ?? ""
    }

    /// The stored model, else the provider config's default, else nil.
    var displayedModel: String? {
        guard let id = selectedProviderID else { return nil }
        let stored = storedModel
        return stored.isEmpty ? source.defaultModel(for: id) : stored
    }

    private var chooserContext: ModelChooserContext? {
        guard let id = selectedProviderID else { return nil }
        return source.chooserContext(for: id, currentModel: displayedModel ?? "")
    }

    private func choose(_ model: String) {
        guard let setting = modelSetting(selectedProviderID) else { return }
        if setting.value != model { setting.value = model }
    }

    /// Follows the model setting the current selection names, so an edit made
    /// elsewhere (another panel, the gear dialog) shows here too.
    private func observeModelSetting() {
        guard let setting = modelSetting(selectedProviderID) else { modelObserver = nil; return }
        modelObserver = UserSettingObserver(setting) { [weak self] _ in self?.modelControl.refresh() }
    }

    // MARK: - Popup

    private func rebuildMenu() {
        choices = Self.menuChoices(leading: leadingChoices, providers: source.providers)
        providerPopup.removeAllItems()
        for choice in choices { providerPopup.addItem(withTitle: choice.label) }
        syncSelection()
        observeModelSetting()
        modelControl.invalidateContext()
        modelControl.refresh()
    }

    /// Points the popup at the stored selection. A stored value matching nothing
    /// is rewritten to the first choice only when the source is authoritative
    /// (a configuration deleted locally); a daemon that has not answered yet
    /// leaves it alone.
    private func syncSelection() {
        let value = selectedSetting.value
        if let index = choices.firstIndex(where: { $0.value == value }) {
            providerPopup.selectItem(at: index)
        } else if !choices.isEmpty {
            providerPopup.selectItem(at: 0)
            if source.isAuthoritative, choices[0].value != value {
                select(choices[0].value)
            }
        }
    }

    @objc private func menuWillOpen() { source.reload() }

    @objc private func popupChanged() {
        let index = providerPopup.indexOfSelectedItem
        guard choices.indices.contains(index) else { return }
        select(choices[index].value)
    }

    /// The provider-change rule: a new provider starts on its default model.
    private func select(_ value: String) {
        guard selectedSetting.value != value else { return }
        let newID = UUID(uuidString: value)
        if let setting = modelSetting(newID), !setting.value.isEmpty { setting.value = "" }
        // Last, so the selection observer's refresh reads the cleared model.
        selectedSetting.value = value
    }

    // MARK: - Layout

    private func buildLayout() {
        providerLabel.setContentHuggingPriority(.required, for: .horizontal)
        providerLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        providerLabel.observeTheme { view, palette in
            view.font = palette.font(.button)
            view.textColor = palette.primaryTextColor
        }
        providerPopup.setAccessibilityTitleUIElement(providerLabel)
        providerPopup.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        let providerRow = NSStackView(views: [providerLabel, providerPopup])
        providerRow.orientation = .horizontal
        providerRow.alignment = .centerY
        providerRow.spacing = 8

        let column = NSStackView(views: [providerRow, modelControl])
        column.orientation = .vertical
        column.alignment = .leading
        column.spacing = 8
        column.translatesAutoresizingMaskIntoConstraints = false
        addSubview(column)
        NSLayoutConstraint.activate([
            column.leadingAnchor.constraint(equalTo: leadingAnchor),
            column.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            column.topAnchor.constraint(equalTo: topAnchor),
            column.bottomAnchor.constraint(equalTo: bottomAnchor),
            providerPopup.widthAnchor.constraint(greaterThanOrEqualToConstant: 220),
            modelControl.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor)
        ])
    }
}
