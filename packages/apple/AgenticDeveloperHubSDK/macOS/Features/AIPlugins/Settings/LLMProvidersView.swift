import SwiftUI
import AppKit
import AIPluginKit
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreMacOS

/// Editor for one configuration: its name and the fields that connect to and
/// authenticate with the provider — nothing else.
///
/// A configuration is a connection, so what is *done* over it — choosing a model,
/// chatting — is not part of this editor. The panel puts a Test Chat card under
/// it (`ProviderConfigPanelViewController`), an `AIChatViewController` pinned to
/// this configuration; when the plugin cannot be reached, that chat is where the
/// reason surfaces, at the first send.
///
/// Sized to its content, not to the pane: the Test Chat card below takes the
/// rest of the height.
struct LLMProviderEditorView: View {

    let configuration: AIProviderConfiguration
    @ObservedObject var viewModel: LLMProvidersListViewModel
    @State private var name: String

    @Environment(\.theme) private var theme

    init(configuration: AIProviderConfiguration, viewModel: LLMProvidersListViewModel) {
        self.configuration = configuration
        self.viewModel = viewModel
        _name = State(initialValue: configuration.name)
    }

    private var template: AIPluginDescriptor.ProviderTemplate? {
        viewModel.pluginManager.template(
            pluginIdentifier: configuration.pluginIdentifier, templateId: configuration.templateId
        )
    }

    private var fields: [AIPluginDescriptor.Field] {
        guard let template else { return [] }
        return viewModel.pluginManager.fields(
            pluginIdentifier: configuration.pluginIdentifier, template: template
        )
    }

    /// The provider identity shown as the detail-pane title (distinct from the
    /// user's editable Name below), e.g. "Anthropic API".
    private var title: String { template?.displayName ?? configuration.name }

    /// Provider · LLM · Config Type, e.g. "Anthropic · Claude · API Key".
    private var subtitle: String {
        guard let template else { return configuration.templateId }
        var parts = [template.resolvedProvider]
        if !template.resolvedLLM.isEmpty { parts.append(template.resolvedLLM) }
        parts.append(template.resolvedConfigType)
        return parts.joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(theme.font(.title))
                Text(subtitle)
                    .font(theme.font(.caption))
                    .foregroundStyle(theme.secondaryText)
            }

            ComposableSettings.SettingsGroup("Connection") {
                ComposableSettings.SettingsCardRow {
                    // Full width, so the card lines up with the Test Chat card
                    // beneath it rather than hugging the form.
                    connectionForm
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.horizontal, ComposableSettings.SettingsLayout.default[.panelInset])
        .padding(.top, ComposableSettings.SettingsLayout.default[.panelInset])
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var connectionForm: some View {
        Form {
            TextField("Name", text: $name)
                .onSubmit {
                    viewModel.rename(configuration.id, to: name)
                    name = viewModel.configuration(for: configuration.id)?.name ?? name
                }

            ForEach(fields, id: \.key) { field in
                if field.isSecret {
                    SecureField(field.label, text: fieldBinding(field))
                } else {
                    TextField(field.label, text: fieldBinding(field),
                              prompt: field.placeholder.map(Text.init))
                }
            }
        }
    }

    private func fieldBinding(_ field: AIPluginDescriptor.Field) -> Binding<String> {
        let setting = AIProviderConfigStore.fieldSetting(config: configuration.id, field: field)
        return Binding(get: { setting.currentValue }, set: { setting.value = $0 })
    }
}
