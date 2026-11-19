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
