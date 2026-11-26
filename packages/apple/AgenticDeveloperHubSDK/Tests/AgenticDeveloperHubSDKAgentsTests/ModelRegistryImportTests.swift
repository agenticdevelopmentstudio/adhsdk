// Tests/AgenticDeveloperHubSDKAgentsTests/ModelRegistryImportTests.swift
import Testing
import Foundation
import AIPluginKit
@testable import AgenticDeveloperHubSDKAgents

@Suite("ModelRegistryImport")
struct ModelRegistryImportTests {

    private static let origin = "com.example.app"

    private func source(
        id: UUID = UUID(), name: String = "Mine", fields: [String: String] = ["baseURL": "https://a"],
        secrets: [String: String] = ["apiKey": "sk-import"], model: String? = "m1"
    ) -> ModelRegistryImport.Source {
        ModelRegistryImport.Source(
            configuration: AIProviderConfiguration(
                id: id, name: name, pluginIdentifier: FakePluginConstants.identifier,
                templateId: FakePluginConstants.templateId),
            fields: fields, secrets: secrets, model: model)
    }

    @Test("imports a configuration with its id, fields, model, origin and secrets")
    func importsOne() throws {
        let secrets = FakeModelSecrets()
        let registry = try makeRegistry(secrets: secrets)
        let one = source()
        let outcome = ModelRegistryImport.run([one], into: registry, origin: Self.origin)

        #expect(outcome.imported == [one.configuration.id])
        let stored = try #require(try registry.get(one.configuration.id))
        #expect(stored.fields == ["baseURL": "https://a"])
        #expect(stored.model == "m1")
        #expect(stored.origin == Self.origin)
        #expect(stored.secretFields == ["apiKey"])
        #expect(secrets.value(for: one.configuration.id, field: "apiKey") == "sk-import")
    }

    @Test("skips the same id, and the same plugin with the same fields")
    func skipsDuplicates() throws {
        let registry = try makeRegistry()
        let one = source()
        _ = ModelRegistryImport.run([one], into: registry, origin: Self.origin)

        let again = ModelRegistryImport.run([one], into: registry, origin: Self.origin)
        #expect(again.skipped == [one.configuration.id])

        let twin = source(name: "Twin")
        let different = source(name: "Other", fields: ["baseURL": "https://b"])
        let outcome = ModelRegistryImport.run([twin, different], into: registry, origin: Self.origin)
        #expect(outcome.skipped == [twin.configuration.id])
        #expect(outcome.imported == [different.configuration.id])
        #expect(try registry.list().count == 2)
    }

    @Test("a failed upsert is reported and does not stop the rest")
    func reportsFailure() throws {
        let registry = try makeRegistry()
        let bad = source(name: "  ", fields: ["baseURL": "https://bad"])
        let good = source(fields: ["baseURL": "https://good"])
        let outcome = ModelRegistryImport.run([bad, good], into: registry, origin: Self.origin)
        #expect(outcome.failed.keys.contains(bad.configuration.id))
        #expect(outcome.imported == [good.configuration.id])
        #expect(outcome.failed.values.allSatisfy { !$0.contains("sk-import") })
    }
}
