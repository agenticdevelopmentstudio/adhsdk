import Testing
import Foundation
import AIPluginKit
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

private final class CSTBackend: ChatBackend, @unchecked Sendable {
    var isReady: Bool { get async { true } }
    func isReadyChanges() -> AsyncStream<Bool> { AsyncStream { $0.yield(true); $0.finish() } }
    func sendMessages(_ messages: [ChatBackendMessage]) async -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            continuation.yield("one")
            continuation.yield("two")
            continuation.finish()
        }
    }
}

private final class CSTRequestCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0
    func next() -> Int { lock.lock(); defer { count += 1; lock.unlock() }; return count }
}

private final class CSTContextRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var history: [AIChatMessage] = []
    private var tools: [AIToolSpec] = []
    func recordHistory(_ messages: [AIChatMessage]) { lock.lock(); history = messages; lock.unlock() }
    func recordTools(_ specs: [AIToolSpec]) { lock.lock(); tools = specs; lock.unlock() }
    var latestHistory: [AIChatMessage] { lock.lock(); defer { lock.unlock() }; return history }
    var latestTools: [AIToolSpec] { lock.lock(); defer { lock.unlock() }; return tools }
}

private final class CSTSource: ChatToolSource, @unchecked Sendable {
    let definition: ToolDefinition
    init(_ definition: ToolDefinition) { self.definition = definition }
    func toolDefinitions() async -> [ToolDefinition] { [definition] }
    func callTool(name: String, argumentsJSON: Data, caller: String?) async -> (content: String, isError: Bool) {
        ("done", false)
    }
}

private final class CSTPlugin: AIPlugin, @unchecked Sendable {
    let recorder: CSTContextRecorder
    init(_ recorder: CSTContextRecorder) { self.recorder = recorder }
    init() { self.recorder = CSTContextRecorder() }
    func buildRequest(_ context: AIChatContext) throws -> AIRequestSpec {
        recorder.recordTools(context.tools)
        return .command(executableURL: URL(fileURLWithPath: "/bin/echo"), arguments: [], stdin: nil, environment: [:])
    }
    func makeDecoder() -> any AIStreamDecoder { CSTDecoder() }
}

private final class CSTDecoder: AIStreamDecoder {
    func consume(_ data: Data) -> [AIStreamEvent] { [] }
}

/// Runs one turn in which the model asks for a single tool call and then ends. Returns after the follow-up
/// request has seen the tool-result message in its history.
private func runOneToolTurn(source: CSTSource, toolId: String, recorder: CSTContextRecorder) async {
    let requests = CSTRequestCounter()
    let factory: LocalChatSession.EventStreamFactory = { _, _ in
        let first = requests.next() == 0
        return AsyncThrowingStream { continuation in
            if first {
                continuation.yield(.toolUse(id: toolId, name: source.definition.name, argumentsJSON: Data("{}".utf8)))
            }
            continuation.yield(.end(stopReason: "end_turn"))
            continuation.finish()
        }
    }
    let session = LocalChatSession(
        resolvePlugin: { CSTPlugin(recorder) },
        makeContext: { history in
            recorder.recordHistory(history)
            return AIChatContext(messages: [], model: "m", systemPrompt: nil, tools: [], config: AIPluginConfig([:]))
        },
        eventStreamFactory: factory,
        toolSource: source
    )
    let stream = session.events()
    let drain = Task { for await _ in stream {} }
    try? await Task.sleep(for: .milliseconds(20))
    session.send("go")
    // The follow-up makeContext call (after the tool ran) sees the tool-result message.
    for _ in 0..<300 {
        if recorder.latestHistory.contains(where: { $0.role == .toolResult }) { break }
        try? await Task.sleep(for: .milliseconds(10))
    }
    try? await Task.sleep(for: .milliseconds(50))
    session.close()
    drain.cancel()
}

@Suite("ChatStreamTypes local-session conformance")
struct ChatStreamTypesLocalSessionTests {

    @Test("chat-tool-types-005: the default tool-aware send yields the text chunks then one end with no stop reason")
    func testV005_defaultStreamEmission() async throws {
        let backend = CSTBackend()
        var events: [ChatStreamEvent] = []
        for try await event in await backend.sendMessages([ChatBackendMessage(role: .user, content: "hi")], tools: []) {
            events.append(event)
        }
        #expect(events.count == 3)
        var chunks: [String] = []
        var ends = 0
        var toolUses = 0
        var lastIsEnd = false
        for event in events {
            switch event {
            case .textDelta(let chunk): chunks.append(chunk); lastIsEnd = false
            case .toolUse: toolUses += 1; lastIsEnd = false
            case .end(let reason):
                ends += 1
                lastIsEnd = true
                #expect(reason == nil)
            }
        }
        #expect(chunks == ["one", "two"])
        #expect(ends == 1)
        #expect(toolUses == 0)
        #expect(lastIsEnd)
    }

    @Test("chat-tool-types-006: the tool-result message carries the id recorded from the tool-use event")
    func testV006_toolCallResultCorrelation() async {
        let recorder = CSTContextRecorder()
        let source = CSTSource(ToolDefinition(name: "search", description: "d", parametersJSONSchema: Data("{}".utf8)))
        await runOneToolTurn(source: source, toolId: "call_1", recorder: recorder)
        let results = recorder.latestHistory.filter { $0.role == .toolResult }
        #expect(results.count == 1)
        #expect(results.first?.toolUseId == "call_1")
    }

    @Test("chat-tool-types-010: the session copies a tool definition's three fields into the tool spec")
    func testV010_definitionCopiedIntoToolSpec() async {
        let recorder = CSTContextRecorder()
        let schema = Data(#"{"type":"object"}"#.utf8)
        let source = CSTSource(ToolDefinition(name: "n", description: "d", parametersJSONSchema: schema))
        await runOneToolTurn(source: source, toolId: "call_x", recorder: recorder)
        let tools = recorder.latestTools
        #expect(tools.count == 1)
        #expect(tools.first?.name == "n")
        #expect(tools.first?.description == "d")
        #expect(tools.first?.parametersJSONSchema == schema)
    }
}
