import XCTest
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

final class ProviderModelPickerViewTests: XCTestCase {

    func testEmptyRegistryShowsLeadingChoicesOnly() {
        let choices = ProviderModelPickerView.menuChoices(
            leading: [.init(label: "Default (Claude CLI)", value: "")], providers: [])
        XCTAssertEqual(choices.map(\.label), ["Default (Claude CLI)"])
        XCTAssertEqual(choices.map(\.value), [""])
    }

    func testDaemonConfigsFollowLeadingChoicesByName() {
        let ollama = DaemonProviderConfig(id: UUID(), name: "Ollama", pluginIdentifier: "p", templateId: "t")
        let anthropic = DaemonProviderConfig(id: UUID(), name: "Anthropic", pluginIdentifier: "p", templateId: "t")
        let choices = ProviderModelPickerView.menuChoices(
            leading: [
                .init(label: "Same as AI Summaries", value: ""),
                .init(label: "Default (Claude CLI)", value: "claude-cli")
            ],
            providers: DaemonProviderRegistrySource.entries(from: [ollama, anthropic]))
        XCTAssertEqual(choices.map(\.label), ["Same as AI Summaries", "Default (Claude CLI)", "Anthropic", "Ollama"])
        XCTAssertEqual(choices[2].value, anthropic.id.uuidString)
    }

    @MainActor
    func testSelectionWritesSettingAndClearsModel() async {
        let setting = UserSetting<String>("test.providerPicker.\(UUID().uuidString)", default: "")
        let model = UserSetting<String>("test.providerPicker.model.\(UUID().uuidString)", default: "")
        defer { setting.remove(); model.remove() }
        model.value = "stale-model"
        let config = DaemonProviderConfig(id: UUID(), name: "Ollama", pluginIdentifier: "p", templateId: "t")
        let source = DaemonProviderRegistrySource(service: StubDaemonService(configs: [config]))
        await source.load()
        let picker = ProviderModelPickerView(
            source: source,
            selectedSetting: setting,
            leadingChoices: [.init(label: "Default (Claude CLI)", value: "")],
            modelSetting: { _ in model })
        XCTAssertEqual(picker.choices.count, 2)
        picker.selectChoice(at: 1)
        XCTAssertEqual(setting.value, config.id.uuidString)
        XCTAssertEqual(model.value, "", "changing the provider starts the new one on its default model")
    }

    @MainActor
    func testAStoredProviderTheListLacksIsKeptAndShownAsUnavailable() async {
        let missing = UUID().uuidString
        let setting = UserSetting<String>("test.providerPicker.\(UUID().uuidString)", default: missing)
        let model = UserSetting<String>("test.providerPicker.model.\(UUID().uuidString)", default: "")
        defer { setting.remove(); model.remove() }
        model.value = "kept-model"
        let config = DaemonProviderConfig(id: UUID(), name: "Ollama", pluginIdentifier: "p", templateId: "t")
        let source = DaemonProviderRegistrySource(service: StubDaemonService(configs: [config]))
        await source.load()
        let picker = ProviderModelPickerView(
            source: source, selectedSetting: setting,
            leadingChoices: [.init(label: "Default (Claude CLI)", value: "")],
            modelSetting: { _ in model })
        XCTAssertEqual(setting.value, missing, "the picker never rewrites a selection it cannot find")
        XCTAssertEqual(model.value, "kept-model")
        XCTAssertEqual(picker.choices.map(\.label),
                       ["Default (Claude CLI)", "Ollama", ProviderModelPickerView.unavailableProviderText])
        XCTAssertEqual(picker.providerPopUpButton.titleOfSelectedItem, ProviderModelPickerView.unavailableProviderText)
        picker.selectChoice(at: 1)
        XCTAssertEqual(picker.choices.count, 2, "the unavailable entry goes once a listed provider is picked")
    }

    @MainActor
    func testTheFirstAnswerNotifiesEvenWhenTheListIsUnchanged() async {
        let source = DaemonProviderRegistrySource(service: StubDaemonService(configs: []))
        var changes = 0
        source.onChange = { changes += 1 }
        await source.load()
        XCTAssertTrue(source.isAuthoritative)
        XCTAssertEqual(changes, 1, "an empty first answer still flips the source to authoritative")
        await source.load()
        XCTAssertEqual(changes, 1, "a later unchanged answer is quiet")
    }

    @MainActor
    func testChoosingTheProvidersDefaultStoresEmptySoItFollowsTheDefault() {
        let source = FixedProviderSource(defaultModel: "claude-sonnet-4-6")
        let setting = UserSetting<String>("test.providerPicker.\(UUID().uuidString)", default: source.id.uuidString)
        let model = UserSetting<String>("test.providerPicker.model.\(UUID().uuidString)", default: "")
        defer { setting.remove(); model.remove() }
        let picker = ProviderModelPickerView(source: source, selectedSetting: setting, modelSetting: { _ in model })
        picker.choose("claude-opus-4-1")
        XCTAssertEqual(model.value, "claude-opus-4-1")
        picker.choose("claude-sonnet-4-6")
        XCTAssertEqual(model.value, "", "the default row stores \"\", which follows the provider's default")
    }

    @MainActor
    func testModelRowShowsStoredModelThenChooseText() async {
        let config = DaemonProviderConfig(id: UUID(), name: "Ollama", pluginIdentifier: "p", templateId: "t")
        let setting = UserSetting<String>("test.providerPicker.\(UUID().uuidString)", default: config.id.uuidString)
        let model = UserSetting<String>("test.providerPicker.model.\(UUID().uuidString)", default: "")
        defer { setting.remove(); model.remove() }
        let source = DaemonProviderRegistrySource(service: StubDaemonService(configs: [config]))
        await source.load()
        let picker = ProviderModelPickerView(
            source: source, selectedSetting: setting, modelSetting: { _ in model })
        // No plugin manager, so no default is known.
        XCTAssertNil(picker.displayedModel)
        XCTAssertEqual(picker.modelPicker.nameText, AIModelPickerControl.chooseModelText)
        model.value = "llama3.2:3b"
        XCTAssertEqual(picker.displayedModel, "llama3.2:3b")
    }
}

/// A daemon that answers from fixtures. Shared by the Stenographer feature tests.
/// Non-final so a test can subclass it to make `summarize` throw or a reply differ.
class StubDaemonService: StenographerDaemonService, @unchecked Sendable {
    var configs: [DaemonProviderConfig]
    var sessionsReply: [SessionDTO]? = []
    var findingsReply: [OversightFindingDTO]? = []
    var scriptsReply: [OversightScript]? = []
    var interactionsReply: [AIInteractionDTO]? = []
    var conversationsReply: [ConversationEntryDTO]? = []
    /// What the daemon's GET /preferences/* answers; nil = daemon unreachable.
    /// Defaults to the values a freshly installed daemon holds.
    var summaryReply: SummaryPreferenceResponse? = SummaryPreferenceResponse(
        enabled: true, selectedConfigId: "", prompt: "", maxWords: SummaryDefaults.maxWords,
        activityLines: SummaryDefaults.activityLines, detailChars: SummaryDefaults.detailChars,
        intervalMinutes: SummaryDefaults.intervalMinutes, maxPerRun: SummaryDefaults.maxPerRun,
        timeoutSeconds: SummaryDefaults.timeoutSeconds)
    var oversightReply: OversightPreferenceResponse? = OversightPreferenceResponse(
        enabled: false, contextThresholdPct: 80, llmEnabled: false, selectedConfigId: "", model: "")
    // What the calls record. The protocol's methods are nonisolated, and every
    // summarizing feature pushes at once, so concurrent calls append from
    // several threads: the lock keeps those appends from tearing the arrays.
    private let lock = NSLock()
    private var recordedSummaryGets = 0
    private var recordedOversightGets = 0
    private var recordedSummaryRequests: [SummaryPreferenceRequest] = []
    private var recordedOversightRequests: [OversightPreferenceRequest] = []
    private var recordedAISyncs: [AIProviderConfigSync] = []
    var summaryGets: Int { lock.withLock { recordedSummaryGets } }
    var oversightGets: Int { lock.withLock { recordedOversightGets } }
    var summaryRequests: [SummaryPreferenceRequest] { lock.withLock { recordedSummaryRequests } }
    var oversightRequests: [OversightPreferenceRequest] { lock.withLock { recordedOversightRequests } }
    /// Every registry the AI config push sent, and whether the daemon takes it.
    var aiSyncs: [AIProviderConfigSync] { lock.withLock { recordedAISyncs } }
    var aiPushResult = true
    private var reconnectHandlers: [@Sendable () -> Void] = []

    init(configs: [DaemonProviderConfig] = []) { self.configs = configs }

    func health() async -> HealthDTO? { HealthDTO(status: "ok", uptime: 1, version: "test") }
    func sessions(
        status: String?, project: String?, sinceHours: Int, includeCounts: Bool
    ) async -> [SessionDTO]? { sessionsReply }
    func session(id: String, includeCounts: Bool) async -> SessionDTO?? {
        .some(sessionsReply?.first { $0.sessionId == id })
    }
    func summarize(sessionId: String) async throws {}
    func conversations(
        limit: Int, includeWorkOutput: Bool, before: String?, sessionId: String?
    ) async -> [ConversationEntryDTO]? { conversationsReply }
    func oversightFindings(status: String?) async -> [OversightFindingDTO]? { findingsReply }
    func oversightActionTarget(findingId: Int) async -> OversightActionTargetDTO? { nil }
    func actOnOversightFinding(findingId: Int) async -> OversightActResultDTO? { nil }
    func oversightScripts() async -> [OversightScript]? { scriptsReply }
    func saveOversightScript(_ script: OversightScript) async -> OversightScript? { script }
    func deleteOversightScript(id: String) async -> Bool { true }
    func resetOversightScript(id: String) async -> OversightScript? { nil }
    func aiInteractions(limit: Int) async -> [AIInteractionDTO]? { interactionsReply }
    func aiInteraction(id: Int) async -> AIInteractionDTO? { interactionsReply?.first { $0.id == id } }
    func aiProviderConfigs() async -> [DaemonProviderConfig]? { configs }
    func summaryPreferences() async -> SummaryPreferenceResponse? {
        lock.withLock { recordedSummaryGets += 1 }
        return summaryReply
    }
    func oversightPreferences() async -> OversightPreferenceResponse? {
        lock.withLock { recordedOversightGets += 1 }
        return oversightReply
    }
    func setSummaryPreferences(_ request: SummaryPreferenceRequest) async -> Bool {
        lock.withLock { recordedSummaryRequests.append(request) }
        return true
    }
    func setOversightPreferences(_ request: OversightPreferenceRequest) async -> Bool {
        lock.withLock { recordedOversightRequests.append(request) }
        return true
    }
    func setAIPreferences(_ sync: AIProviderConfigSync) async -> Bool {
        lock.withLock { recordedAISyncs.append(sync) }
        return aiPushResult
    }
    func onReconnect(_ handler: @escaping @Sendable () -> Void) { reconnectHandlers.append(handler) }
    func fireReconnect() { reconnectHandlers.forEach { $0() } }
}

/// One provider with a known default model and no chooser.
@MainActor
final class FixedProviderSource: ProviderRegistrySource {
    let id = UUID()
    let defaultModelID: String
    var onChange: (@MainActor () -> Void)?
    let isAuthoritative = true
    init(defaultModel: String) { defaultModelID = defaultModel }
    var providers: [ProviderRegistryEntry] { [.init(id: id, name: "Fixed")] }
    func reload() {}
    func defaultModel(for id: UUID) -> String? { id == self.id ? defaultModelID : nil }
    func chooserContext(for id: UUID, currentModel: String) -> ModelChooserContext? { nil }
}
