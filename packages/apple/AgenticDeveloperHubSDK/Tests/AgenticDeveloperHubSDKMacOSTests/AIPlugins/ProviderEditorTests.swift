import AppKit
import Foundation
import Testing
@testable import AIPluginKit
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// The AI Providers panel's names for a configuration and its editor's rows
/// (ai-providers-panel vectors ai-providers-panel-001 to 005).
@Suite("AI Providers editor", .serialized, .exclusiveAccess(to: .userSettings))
@MainActor
struct ProviderEditorTests {

    // MARK: - Titles

    /// ai-providers-panel-001
    @Test func theSubtitleJoinsTheThreePartsWithDashes() {
        let template = AIPluginDescriptor.ProviderTemplate(
            id: "openai", displayName: "OpenAI API", provider: "OpenAI", llm: "GPT", configType: "API key")
        #expect(ProviderConfigTitles.subtitle(template: template) == "OpenAI - GPT - API key")
        #expect(ProviderConfigTitles.title(template: template) == "OpenAI, GPT, API key")
    }

    /// ai-providers-panel-002
    @Test func anEmptyPartIsDropped() {
        let template = AIPluginDescriptor.ProviderTemplate(
            id: "ollama", displayName: "Ollama", provider: "Ollama", llm: "", configType: "Local")
        #expect(ProviderConfigTitles.subtitle(template: template) == "Ollama - Local")
        #expect(ProviderConfigTitles.title(template: template) == "Ollama, Local")
    }

    @Test func noTemplateHasNoSubtitle() {
        #expect(ProviderConfigTitles.subtitle(template: nil) == nil)
        #expect(ProviderConfigTitles.title(template: nil) == "")
    }

    @Test func theResolvedPartsFillInWhatTheTemplateLeavesOut() {
        // Provider falls back to the display name, config type to "API Key".
        let template = AIPluginDescriptor.ProviderTemplate(id: "groq", displayName: "Groq")
        #expect(ProviderConfigTitles.subtitle(template: template) == "Groq - API Key")
    }

    // MARK: - Editor

    private func manager() -> AIPluginManager {
        let pluginManager = AIPluginManager(searchPaths: [], appName: "Test")
        pluginManager.registerForTesting(AIPluginDescriptor(
            schemaVersion: 3, identifier: "com.x.editor-tests", displayName: "OpenAI-compatible",
            version: "1.0",
            fields: [.init(key: "baseURL", label: "Base URL", kind: .text),
                     .init(key: "apiKey", label: "API Key", kind: .secret)],
            templates: [.init(id: "openai", displayName: "OpenAI API",
                              defaultValues: ["baseURL": "https://api.openai.com/v1"],
                              models: ["gpt-5", "gpt-5-mini"], defaultModel: "gpt-5",
                              provider: "OpenAI", llm: "GPT", configType: "API key")]
        ))
        return pluginManager
    }

    private func withEditor(_ body: (LLMProviderEditorView, AIProviderConfiguration) throws -> Void) throws {
        UserSettings.aiProviderConfigurations.value = []
        let viewModel = LLMProvidersListViewModel(pluginManager: manager())
        let template = try #require(viewModel.availableTemplates.first)
        viewModel.add(template)
        let config = try #require(viewModel.configurations.first)
        defer { viewModel.remove(config.id) }
        try body(LLMProviderEditorView(configuration: config, viewModel: viewModel), config)
    }

    @Test func theEditorIsTitledWithTheCommaJoinedParts() throws {
        try withEditor { editor, _ in
            #expect(editor.titleLabel.stringValue == "OpenAI, GPT, API key")
        }
    }

    /// ai-providers-panel-004
    @Test func theConnectionGroupIsUntitledAndHasNoFreeTextModelField() throws {
        try withEditor { editor, _ in
            #expect(editor.group.title == nil)
            #expect(!editor.fieldRows.contains { $0.label.stringValue.localizedCaseInsensitiveContains("model") })
            #expect(editor.nameRow.label.stringValue == "Name")
        }
    }

    /// ai-providers-panel-005: secret fields get the reveal row; the others stay plain.
    @Test func secretFieldsUseTheRevealRow() throws {
        try withEditor { editor, _ in
            let rows = Dictionary(uniqueKeysWithValues: editor.fieldRows.map { ($0.label.stringValue, $0) })
            #expect(rows["API Key"] is ComposableSettings.SecureTextEditView)
            #expect(!(rows["Base URL"] is ComposableSettings.SecureTextEditView))
        }
    }

    /// ai-providers-panel-003
    @Test func theDefaultModelRowNamesTheTemplateDefaultAndWritesAChoice() throws {
        try withEditor { editor, config in
            let template = try #require(manager().template(
                pluginIdentifier: config.pluginIdentifier, templateId: config.templateId))
            let setting = AIProviderConfigStore.modelSetting(config: config.id, template: template)
            setting.value = ""
            defer { setting.value = "" }
            editor.modelPicker?.refresh()

            let picker = try #require(editor.modelPicker)
            #expect(picker.label == "Default Model")
            #expect(picker.nameText == "gpt-5")

            editor.chooseDefaultModel("gpt-5-mini")
            #expect(setting.currentValue == "gpt-5-mini")
            #expect(picker.nameText == "gpt-5-mini")
        }
    }
}
