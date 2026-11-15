import Testing
import Foundation
import AgenticDeveloperHubSDKCore

@Suite("CustomHeuristicStore conformance")
struct CustomHeuristicStoreConformanceTests {

    private func makeRoot() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("heuristic-store-\(UUID().uuidString)")
    }

    private func makeRules() -> [CustomHeuristicRule] {
        let created = Date(timeIntervalSince1970: 1_700_000_000)
        return [
            CustomHeuristicRule(
                appName: "Jira", titlePattern: "JIRA-\\d+", matchMode: .regex,
                autoAssign: true, targetContextName: "Work", createdAt: created
            ),
            CustomHeuristicRule(appName: "Notes", titlePattern: "Daily", createdAt: created)
        ]
    }

    @Test("window-matching-027: loading from a directory with no file returns an empty list")
    func loadMissing() throws {
        let root = makeRoot()
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        #expect(try CustomHeuristicStore(rootDirectory: root).loadRules().isEmpty)
    }

    @Test("window-matching-028: save creates the directory, writes sorted pretty JSON, and round-trips")
    func saveAndLoad() throws {
        let parent = makeRoot()
        let root = parent.appendingPathComponent("nested").appendingPathComponent("deeper")
        defer { try? FileManager.default.removeItem(at: parent) }
        let store = CustomHeuristicStore(rootDirectory: root)
        let rules = makeRules()

        try store.saveRules(rules)

        var isDirectory: ObjCBool = false
        #expect(FileManager.default.fileExists(atPath: root.path, isDirectory: &isDirectory))
        #expect(isDirectory.boolValue)
        #expect(store.heuristicsFilePath.lastPathComponent == "heuristics.json")

        let text = try String(contentsOf: store.heuristicsFilePath, encoding: .utf8)
        #expect(text.contains("\n  "))
        let appName = try #require(text.range(of: "\"appName\""))
        let createdAt = try #require(text.range(of: "\"createdAt\""))
        let identifier = try #require(text.range(of: "\"id\""))
        let titlePattern = try #require(text.range(of: "\"titlePattern\""))
        #expect(appName.lowerBound < createdAt.lowerBound)
        #expect(createdAt.lowerBound < identifier.lowerBound)
        #expect(identifier.lowerBound < titlePattern.lowerBound)
        #expect(text.contains("2023-11-14T22:13:20Z"))

        #expect(try store.loadRules() == rules)
    }

    @Test("window-matching-029: loading a corrupt file throws a decoding error")
    func loadCorrupt() throws {
        let root = makeRoot()
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = CustomHeuristicStore(rootDirectory: root)
        try Data("not json".utf8).write(to: store.heuristicsFilePath)

        #expect(throws: DecodingError.self) { try store.loadRules() }
    }

    @Test("window-matching-030: removeAll deletes the file, keeps the directory, and is repeatable")
    func removeAll() throws {
        let root = makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let store = CustomHeuristicStore(rootDirectory: root)
        try store.saveRules(makeRules())

        try store.removeAll()
        #expect(!FileManager.default.fileExists(atPath: store.heuristicsFilePath.path))
        #expect(FileManager.default.fileExists(atPath: root.path))
        try store.removeAll()
    }
}
