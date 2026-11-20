import AppKit
import Combine
import AIPluginKit
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreMacOS

/// The words a configuration is named by, built from its template's resolved
/// provider, LLM and config type with the empty ones dropped.
enum ProviderConfigTitles {

    /// The settings sidebar row's subtitle: "Provider - LLM - Config type".
    /// Nil when all three parts are empty.
    static func subtitle(template: AIPluginDescriptor.ProviderTemplate?) -> String? {
        let text = parts(template).joined(separator: " - ")
        return text.isEmpty ? nil : text
    }

    /// The editor's title: "Provider, LLM, Config type".
    static func title(template: AIPluginDescriptor.ProviderTemplate?) -> String {
        parts(template).joined(separator: ", ")
    }

    private static func parts(_ template: AIPluginDescriptor.ProviderTemplate?) -> [String] {
        guard let template else { return [] }
        return [template.resolvedProvider, template.resolvedLLM, template.resolvedConfigType]
            .filter { !$0.isEmpty }
    }
}

/// Editor for one configuration: its name, the fields that connect to and
/// authenticate with the provider, and the configuration's default model.
///
/// What is *done* over the connection — chatting — is not part of this editor.
/// The panel puts a Test Chat card under it (`ProviderConfigPanelViewController`),
/// an `AIChatViewController` pinned to this configuration; when the plugin
/// cannot be reached, that chat is where the reason surfaces, at the first send.
///
/// Built from the ComposableSettings row views, so a secret field is a
/// ``ComposableSettings/SecureTextEditView`` with its copy and reveal buttons,
/// and the default model is an ``AIModelPickerControl`` row like every other
/// model choice. Sized to its content, not to the pane: the Test Chat card
/// below takes the rest of the height.
@MainActor
final class LLMProviderEditorView: NSView {

    let configuration: AIProviderConfiguration
    private let viewModel: LLMProvidersListViewModel
    private let template: AIPluginDescriptor.ProviderTemplate?

    let titleLabel: ThemedLabel
    let group = ComposableSettings.GroupView(withHeaderView: NSView())
    private(set) var nameRow: ComposableSettings.TextEditView!
    /// One row per template field, in the plugin's order.
    private(set) var fieldRows: [ComposableSettings.TextEditView] = []
    /// Nil when the configuration's template cannot be resolved.
    private(set) var modelPicker: AIModelPickerControl?

    private var nameModel: ComposableSettings.ViewModel<String>!
    private var modelObserver: UserSettingObserver<String>?
    /// The connection fields (base URL, API key): an edit changes what the
    /// Default Model row's context describes.
    private var fieldObservers: [UserSettingObserver<String>] = []
    private var configurationsObserver: AnyCancellable?

    init(configuration: AIProviderConfiguration, viewModel: LLMProvidersListViewModel) {
        self.configuration = configuration
        self.viewModel = viewModel
        let template = viewModel.pluginManager.template(
            pluginIdentifier: configuration.pluginIdentifier, templateId: configuration.templateId)
        self.template = template
        let title = ProviderConfigTitles.title(template: template)
        self.titleLabel = ThemedLabel(string: title.isEmpty ? configuration.name : title, textRole: .title)
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        buildRows()
        buildLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Rows

    private func buildRows() {
        let id = configuration.id
        let nameModel = ComposableSettings.ViewModel<String>(
            title: "Name",
            get: { [weak viewModel] in viewModel?.configuration(for: id)?.name ?? "" },
            set: { [weak viewModel] in viewModel?.rename(id, to: $0) })
        self.nameModel = nameModel
        nameRow = ComposableSettings.TextEditView(with: nameModel)
        group.addSettingSubview(nameRow)
        // A rename can come back uniqued ("Claude 2"); re-show what was stored.
        configurationsObserver = viewModel.$configurations
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.nameModel.refresh() }

        if let template {
            let fields = viewModel.pluginManager.fields(
                pluginIdentifier: configuration.pluginIdentifier, template: template)
            for field in fields {
                let model = ComposableSettings.ViewModel<String>(
                    title: field.label,
                    setting: AIProviderConfigStore.fieldSetting(config: id, field: field))
                let row: ComposableSettings.TextEditView = field.isSecret
                    ? ComposableSettings.SecureTextEditView(with: model)
                    : ComposableSettings.TextEditView(with: model)
                row.placeholder = field.placeholder
                fieldRows.append(row)
                group.addSettingSubview(row)
            }
            addModelPicker(template: template)
        }
    }

    private func addModelPicker(template: AIPluginDescriptor.ProviderTemplate) {
        let configuration = configuration
        let pluginManager = viewModel.pluginManager
        let setting = AIProviderConfigStore.modelSetting(config: configuration.id, template: template)
        let picker = AIModelPickerControl(
            label: "Default Model",
            displayName: { AIProviderConfigStore.selectedModel(config: configuration, template: template) },
            context: {
                ProviderChooserContexts.context(
                    config: configuration, template: template, pluginManager: pluginManager,
                    currentModel: setting.currentValue)
            },
            onChoose: { [weak self] in self?.chooseDefaultModel($0) })
        modelPicker = picker
        group.addSettingSubview(picker)
        // The Test Chat below writes the same setting; follow it.
        modelObserver = UserSettingObserver(setting) { [weak picker] _ in picker?.refresh() }
        let fields = pluginManager.fields(pluginIdentifier: configuration.pluginIdentifier, template: template)
        fieldObservers = fields.map { field in
            let fieldSetting = AIProviderConfigStore.fieldSetting(config: configuration.id, field: field)
            return UserSettingObserver(fieldSetting) { [weak picker] _ in
                picker?.invalidateContext()
                picker?.refresh()
            }
        }
    }

    /// Stores `model` as the configuration's default model, as a choice in
    /// the Default Model row's chooser does.
    func chooseDefaultModel(_ model: String) {
        guard let template else { return }
        AIProviderConfigStore.modelSetting(config: configuration.id, template: template).value = model
        modelPicker?.refresh()
    }

    // MARK: - Layout

    private func buildLayout() {
        let layout = ComposableSettings.SettingsLayout.default
        let inset = layout[.panelInset]
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.setAccessibilityIdentifier("providers.editor.title")

        let stack = NSStackView(views: [titleLabel, group])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = layout[.captionSpacing]
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: inset),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
