// Tests/AgenticDeveloperHubSDKCoreTests/Chat/CompositeChatToolSourceTests.swift
import Testing
import Foundation
@testable import AgenticDeveloperHubSDKCore

private final class RecordingSource: ChatToolSource, @unchecked Sendable {
    let names: [String]
    var calls: [(String, String?)] = []
    init(_ names: [String]) { self.names = names }
    func toolDefinitions() async -> [ToolDefinition] {
        names.map {
            ToolDefinition(name: $0, description: $0, parametersJSONSchema: ToolJSONSchema.object(properties: [:]))
        }
    }
    func callTool(name: String, argumentsJSON: Data, caller: String?) async -> (content: String, isError: Bool) {
        calls.append((name, caller))
        return ("\(name) ok", false)
    }
}

/// Advertises its names only once `enabled` is set (when `gated`), and logs start/finish of each definitions query.
private final class GatedSource: ChatToolSource, @unchecked Sendable {
    private let lock = NSLock()
    private var enabled: Bool
    private var _calls: [String] = []
    var calls: [String] { lock.withLock { _calls } }
    let name: String
    let log: ConformanceLog?
    let result: (content: String, isError: Bool)
    init(_ name: String, enabled: Bool = true, log: ConformanceLog? = nil, result: (String, Bool) = ("ok", false)) {
        self.name = name; self.enabled = enabled; self.log = log; self.result = result
    }
    func enable() { lock.withLock { enabled = true } }
    func toolDefinitions() async -> [ToolDefinition] {
        log?.record("start \(name)")
        try? await Task.sleep(for: .milliseconds(20))
        let isOn = lock.withLock { enabled }
        log?.record("finish \(name)")
        guard isOn else { return [] }
        return [ToolDefinition(
            name: "x", description: name, parametersJSONSchema: ToolJSONSchema.object(properties: [:]))]
    }
    func callTool(name: String, argumentsJSON: Data, caller: String?) async -> (content: String, isError: Bool) {
        lock.withLock { _calls.append(name) }
        return result
    }
}

private final class ConformanceLog: @unchecked Sendable {
    private let lock = NSLock()
    private var entries: [String] = []
    func record(_ message: String) { lock.lock(); entries.append(message); lock.unlock() }
    var all: [String] { lock.lock(); defer { lock.unlock() }; return entries }
}

@Suite("CompositeChatToolSource conformance")
struct CompositeChatToolSourceConformanceTests {
    @Test("composite-tool-source-005: empty sources advertise nothing")
    func testV005_emptySourcesEmptyDefinitions() async {
        let composite = CompositeChatToolSource([])
        #expect(await composite.toolDefinitions().isEmpty)
    }

    @Test("composite-tool-source-006: empty sources answer an unknown-tool error")
    func testV006_emptySourcesUnknownTool() async {
        let composite = CompositeChatToolSource([])
        let result = await composite.callTool(name: "a", argumentsJSON: Data(), caller: nil)
        #expect(result.content == "unknown tool a")
        #expect(result.isError)
    }

    @Test("composite-tool-source-007: duplicates are kept and the first source wins the call")
    func testV007_firstMatchWinsDefinitionsNotDeduplicated() async {
        let first = GatedSource("A")
        let second = GatedSource("B")
        let composite = CompositeChatToolSource([first, second])
        let names = await composite.toolDefinitions().map(\.name)
        #expect(names == ["x", "x"])
        _ = await composite.callTool(name: "x", argumentsJSON: Data(), caller: nil)
        #expect(first.calls == ["x"])
        #expect(second.calls.isEmpty)
    }

    @Test("composite-tool-source-008: routing re-queries definitions on every call")
    func testV008_callResolvesByFreshDefinitions() async {
        let first = GatedSource("A", enabled: false)
        let second = GatedSource("B")
        let composite = CompositeChatToolSource([first, second])
        _ = await composite.callTool(name: "x", argumentsJSON: Data(), caller: nil)
        #expect(first.calls.isEmpty)
        #expect(second.calls == ["x"])
        first.enable()
        _ = await composite.callTool(name: "x", argumentsJSON: Data(), caller: nil)
        #expect(first.calls == ["x"])
        #expect(second.calls == ["x"])
    }

    @Test("composite-tool-source-009: definitions are awaited one source at first time, in order")
    func testV009_definitionsAwaitedSequentially() async {
        let log = ConformanceLog()
        let composite = CompositeChatToolSource([
            GatedSource("A", log: log), GatedSource("B", log: log), GatedSource("C", log: log)
        ])
        let defs = await composite.toolDefinitions()
        #expect(log.all == ["start A", "finish A", "start B", "finish B", "start C", "finish C"])
        #expect(defs.map(\.description) == ["A", "B", "C"])
    }

    @Test("composite-tool-source-010: the chosen source's result passes through unchanged")
    func testV010_callResultPassthrough() async {
        let composite = CompositeChatToolSource([GatedSource("A", result: ("boom", true))])
        let result = await composite.callTool(name: "x", argumentsJSON: Data(), caller: nil)
        #expect(result.content == "boom")
        #expect(result.isError == true)
    }
}

@Suite("CompositeChatToolSource")
struct CompositeChatToolSourceTests {
    @Test("concatenates definitions in order")
    func concatenatesDefinitionsInOrder() async {
        let composite = CompositeChatToolSource([RecordingSource(["a", "b"]), RecordingSource(["c"])])
        let names = await composite.toolDefinitions().map(\.name)
        #expect(names == ["a", "b", "c"])
    }

    @Test("routes by name and passes the caller")
    func routesByNameAndPassesCaller() async {
        let first = RecordingSource(["a"]), second = RecordingSource(["b"])
        let composite = CompositeChatToolSource([first, second])
        let result = await composite.callTool(name: "b", argumentsJSON: Data("{}".utf8), caller: "pane-1")
        #expect(result.content == "b ok")
        #expect(second.calls.first?.0 == "b")
        #expect(second.calls.first?.1 == "pane-1")
        #expect(first.calls.isEmpty)
    }

    @Test("an unknown tool is a sentence")
    func unknownToolIsASentence() async {
        let composite = CompositeChatToolSource([RecordingSource(["a"])])
        let result = await composite.callTool(name: "zzz", argumentsJSON: Data(), caller: nil)
        #expect(result.isError)
        #expect(result.content == "unknown tool zzz")
    }

    @Test("the two-argument call forwards with a nil caller")
    func twoArgumentCallForwardsWithNilCaller() async {
        let source = RecordingSource(["a"])
        _ = await source.callTool(name: "a", argumentsJSON: Data())
        #expect(source.calls.count == 1)
        #expect(source.calls.first?.1 == nil)
    }
}
