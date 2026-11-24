import CoreGraphics
import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("SystemWindowContextStore conformance")
struct SystemWindowContextStoreConformanceTests {

    // MARK: - Helpers

    private let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeRoot() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("context-store-\(UUID().uuidString)")
    }

    private func makeContext(name: String) -> SystemWindowContext {
        let fingerprint = SystemWindowFingerprint(
            app: "Mail", titlePattern: "", matchStrategy: .appOnly, display: 0
        )
        let snapshot = SystemWindowSnapshot(
            windowID: nil, fingerprint: fingerprint, savedFrame: .zero, display: 0,
            app: "Mail", title: "", lastSeen: fixedDate
        )
        return SystemWindowContext(name: name, windowSnapshots: [snapshot], createdAt: fixedDate)
    }

    // MARK: - State

    @Test("contexts-007: loading state from an empty root returns an empty state")
    func loadStateMissing() throws {
        let root = makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let state = try SystemWindowContextStore(rootDirectory: root).loadState()
        #expect(state.activeContextID == nil)
        #expect(state.contextIDs.isEmpty)
    }

    @Test("contexts-008: saveAll writes one file per context, a sorted state file and a lock file")
    func saveAllLayout() throws {
        let root = makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let store = SystemWindowContextStore(rootDirectory: root)
        let first = makeContext(name: "A")
        let second = makeContext(name: "B")

        try store.saveAll(contexts: [first, second], activeContextID: second.id)

        let manager = FileManager.default
        #expect(manager.fileExists(atPath: root.appendingPathComponent("contexts/\(first.id.uuidString).json").path))
        #expect(manager.fileExists(atPath: root.appendingPathComponent("contexts/\(second.id.uuidString).json").path))
        #expect(manager.fileExists(atPath: root.appendingPathComponent(".lock").path))

        let state = try store.loadState()
        #expect(state.activeContextID == second.id)
        #expect(state.contextIDs == [first.id, second.id])

        let text = try String(contentsOf: store.stateFilePath, encoding: .utf8)
        let activeKey = try #require(text.range(of: "\"activeContextID\""))
        let idsKey = try #require(text.range(of: "\"contextIDs\""))
        #expect(activeKey.lowerBound < idsKey.lowerBound)
    }

    @Test("contexts-009: loadAllContexts skips a corrupt context file without throwing")
    func loadAllSkipsCorrupt() throws {
        let root = makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let store = SystemWindowContextStore(rootDirectory: root)
        let first = makeContext(name: "A")
        let second = makeContext(name: "B")
        try store.saveAll(contexts: [first, second], activeContextID: second.id)
        try Data("not json".utf8).write(to: store.contextFilePath(for: first.id))

        #expect(try store.loadAllContexts() == [second])
    }

    @Test("contexts-010: a corrupt state file throws decodingFailed with its path")
    func loadStateCorrupt() throws {
        let root = makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let store = SystemWindowContextStore(rootDirectory: root)
        try store.ensureDirectoryStructure()
        try Data("{".utf8).write(to: store.stateFilePath)

        do {
            _ = try store.loadState()
            Issue.record("loadState should throw")
        } catch SystemWindowContextStoreError.decodingFailed(let path, _) {
            #expect(path == store.stateFilePath.path)
        } catch {
            Issue.record("expected decodingFailed, got \(error)")
        }
    }

    @Test("contexts-011: loading an unknown context throws contextNotFound with its id")
    func loadContextMissing() {
        let store = SystemWindowContextStore(rootDirectory: makeRoot())
        let missing = UUID()
        do {
            _ = try store.loadContext(id: missing)
            Issue.record("loadContext should throw")
        } catch SystemWindowContextStoreError.contextNotFound(let id) {
            #expect(id == missing)
        } catch {
            Issue.record("expected contextNotFound, got \(error)")
        }
    }

    @Test("contexts-012: listContextFiles returns only files named by a UUID with a .json suffix")
    func listContextFiles() throws {
        let root = makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let store = SystemWindowContextStore(rootDirectory: root)
        try store.ensureDirectoryStructure()
        let valid = UUID()
        for name in ["\(valid.uuidString).json", "notes.txt", "bad.json"] {
            try Data("{}".utf8).write(to: store.contextsDirectory.appendingPathComponent(name))
        }

        #expect(try store.listContextFiles() == [valid])
    }

    @Test("contexts-013: deleting a context that has no file succeeds")
    func deleteMissingContext() throws {
        let root = makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        try SystemWindowContextStore(rootDirectory: root).deleteContext(id: UUID())
    }

    @Test("contexts-014: saveAll does not prune files of contexts that are no longer listed")
    func saveAllNoPrune() throws {
        let root = makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let store = SystemWindowContextStore(rootDirectory: root)
        let first = makeContext(name: "A")
        let second = makeContext(name: "B")

        try store.saveAll(contexts: [first, second], activeContextID: nil)
        try store.saveAll(contexts: [second], activeContextID: nil)

        #expect(FileManager.default.fileExists(atPath: store.contextFilePath(for: first.id).path))
        #expect(try store.loadState().contextIDs == [second.id])
    }

    // MARK: - Settings

    @Test("contexts-015: an empty settings object decodes to the defaults")
    func settingsLenientDecode() throws {
        let settings = try JSONDecoder().decode(SystemWindowContextsSettings.self, from: Data("{}".utf8))
        #expect(!settings.launchAtLogin)
        #expect(settings.reconcileBehavior == .prompt)
        #expect(settings.hiddenApps.isEmpty)
        #expect(!settings.showAppInDock)
    }

    @Test("contexts-016: a value of the wrong JSON type fails to decode")
    func settingsTypedDecode() {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(SystemWindowContextsSettings.self, from: Data("{\"launchAtLogin\":\"yes\"}".utf8))
        }
    }

    @Test("contexts-017: the reconcile behaviors are prompt, auto and ignore in order")
    func reconcileBehaviorCases() {
        #expect(ReconcileBehavior.allCases.map(\.rawValue) == ["prompt", "auto", "ignore"])
    }
}
