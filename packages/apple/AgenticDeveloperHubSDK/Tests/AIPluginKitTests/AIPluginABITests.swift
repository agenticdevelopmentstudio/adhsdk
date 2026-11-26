import Testing
import Foundation
@testable import AIPluginKit

/// The AIPluginKit ABI stamp: discovery refuses a `.aiplugin` whose
/// `AIPluginKitABIVersion` is missing or differs, reports the refusal as a load
/// failure, and never loads its code. Fixtures are descriptor-only bundles, so a
/// refused one that were loaded would fail differently (no executable).
@Suite("AIPluginABI")
@MainActor
final class AIPluginABITests {

    private let tempDir: URL

    init() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("aiplugin-abi-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: tempDir)
    }

    @Test("refuses a bundle stamped with another ABI")
    func refusesAMismatchedStamp() throws {
        try writeBundle(id: "com.test.newer", name: "Newer", stamp: AIPluginABI.version + 1)

        let scan = AIPluginManager.scanPlugins(in: [tempDir])

        #expect(scan.plugins.isEmpty)
        #expect(scan.refused == [PluginLoadFailure(
            identifier: "com.test.newer", displayName: "Newer",
            message: "Plugin 'Newer' was built against AIPluginKit ABI \(AIPluginABI.version + 1), "
                + "but this host has ABI \(AIPluginABI.version); rebuild the plugin")])
    }

    @Test("refuses a bundle with no stamp")
    func refusesAMissingStamp() throws {
        try writeBundle(id: "com.test.old", name: "Old", stamp: nil)

        let scan = AIPluginManager.scanPlugins(in: [tempDir])

        #expect(scan.plugins.isEmpty)
        #expect(scan.refused.map(\.message) == [
            "Plugin 'Old' has no AIPluginKit ABI stamp (AIPluginKitABIVersion); rebuild it against this AIPluginKit"
        ])
    }

    @Test("accepts a bundle stamped with this ABI")
    func acceptsAMatchingStamp() throws {
        try writeBundle(id: "com.test.current", name: "Current", stamp: AIPluginABI.version)

        let scan = AIPluginManager.scanPlugins(in: [tempDir])

        #expect(scan.plugins.map(\.descriptor.identifier) == ["com.test.current"])
        #expect(scan.refused.isEmpty)
        #expect(AIPluginManager.scanDescriptors(in: [tempDir]).count == 1)
    }

    @Test("loading all plugins reports the refusals and loads nothing")
    func loadAllReportsRefusals() throws {
        try writeBundle(id: "com.test.newer", name: "Newer", stamp: AIPluginABI.version + 1)
        let manager = AIPluginManager(searchPaths: [tempDir])

        manager.discoverPlugins()
        manager.discoverPlugins()
        let result = manager.loadAllPlugins()

        #expect(manager.descriptors.isEmpty)
        #expect(manager.discoveryFailures.map(\.identifier) == ["com.test.newer"])
        #expect(result.loaded.isEmpty)
        #expect(result.failures.map(\.identifier) == ["com.test.newer"])
        #expect(throws: AIPluginManager.AIPluginError.self) {
            try manager.loadPlugin(identifier: "com.test.newer")
        }
    }

    @Test("the plugin runtime's refused seam lists the refusals")
    func runtimeReportsRefusals() async throws {
        try writeBundle(id: "com.test.newer", name: "Newer", stamp: AIPluginABI.version + 1)
        let runtime = DaemonAIChat.PluginRuntime.live

        let refused = await runtime.refused([tempDir])
        let discovered = await runtime.discover([tempDir])

        #expect(refused.map(\.identifier).contains("com.test.newer"))
        #expect(!discovered.contains { $0.identifier == "com.test.newer" })
        do {
            _ = try await runtime.load("com.test.newer", [tempDir])
            Issue.record("A refused plugin must not load")
        } catch {
            #expect(error.localizedDescription.contains("AIPluginKit ABI"))
        }
    }

    @Test("a non-integer stamp is refused as missing")
    func refusesAMalformedStamp() {
        #expect(AIPluginABI.incompatibility(stamp: "1", name: "P")?.contains("no AIPluginKit ABI stamp") == true)
        #expect(AIPluginABI.incompatibility(stamp: true, name: "P")?.contains("no AIPluginKit ABI stamp") == true)
        #expect(AIPluginABI.incompatibility(stamp: AIPluginABI.version, name: "P") == nil)
    }

    // MARK: - Fixtures

    private func writeBundle(id: String, name: String, stamp: Int?) throws {
        let bundle = tempDir.appendingPathComponent("\(name).aiplugin", isDirectory: true)
        let resources = bundle.appendingPathComponent("Contents/Resources", isDirectory: true)
        try FileManager.default.createDirectory(at: resources, withIntermediateDirectories: true)
        let descriptor: [String: Any] = [
            "schemaVersion": AIPluginDescriptor.currentSchemaVersion,
            "identifier": id,
            "displayName": name,
            "version": "1.0.0",
            "models": ["m1"],
            "fields": []
        ]
        try JSONSerialization.data(withJSONObject: descriptor)
            .write(to: resources.appendingPathComponent("descriptor.json"))
        try AIPluginABI.stampForTesting(bundleAt: bundle, stamp: stamp)
    }
}
