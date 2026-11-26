import AgenticDeveloperHubSDKCore
import AIPluginKit
import XCTest
@testable import AgenticDeveloperHubSDKDatabase

final class ModelProviderResolverTests: XCTestCase {
    private let id = UUID()

    /// A resolver over one configuration, its settings rows and its key.
    private func resolver(
        plugin: String, template: String = "default", name: String = "Mine", model: String = "some-model",
        fields: [String: String] = [:], key: String? = "secret-key", keyRequired: Bool = true
    ) -> ModelProviderResolver {
        let config = AIProviderConfiguration(id: id, name: name, pluginIdentifier: plugin, templateId: template)
        let list = (try? JSONEncoder().encode([config])).flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        var rows: [String: String] = [
            AIProviderConfigKeys.configurationsKey: list,
            AIProviderConfigKeys.modelKey(config: id): model
        ]
        for (field, value) in fields { rows[AIProviderConfigKeys.fieldKey(config: id, field: field)] = value }
        let settings = rows
        let keyName = AIProviderConfigKeys.fieldKey(config: id, field: "apiKey")
        return ModelProviderResolver(
            settings: { settings[$0] },
            secret: { $0 == keyName ? key : nil },
            secretRequired: { _, _ in keyRequired })
    }

    func testOpenAICompatibleBaseWithoutAVersionGetsV1() throws {
        let route = try XCTUnwrap(resolver(
            plugin: ModelProviderResolver.openAICompatiblePlugin, template: "ollama", name: "Local Ollama",
            model: "qwen3:8b", fields: ["baseURL": "http://localhost:11434"]).route(id))
        XCTAssertEqual(route.endpoint.absoluteString, "http://localhost:11434/v1/chat/completions")
        XCTAssertEqual(route.wire, .chatCompletions(maxTokensKey: "max_tokens"))
        XCTAssertEqual(route.name, "Local Ollama")
        XCTAssertEqual(route.model, "qwen3:8b")
        XCTAssertEqual(route.configID, id)
    }

    func testOpenAICompatibleVersionedBaseIsKept() throws {
        let route = try XCTUnwrap(resolver(
            plugin: ModelProviderResolver.openAICompatiblePlugin,
            fields: ["baseURL": "https://api.groq.com/openai/v1/"]).route(id))
        XCTAssertEqual(route.endpoint.absoluteString, "https://api.groq.com/openai/v1/chat/completions")
    }

    func testOpenAICompatibleWithoutABaseIsNil() {
        XCTAssertNil(resolver(plugin: ModelProviderResolver.openAICompatiblePlugin).route(id))
    }

    func testOpenAIWithNoBaseUsesTheOpenAIAPI() throws {
        let route = try XCTUnwrap(resolver(plugin: ModelProviderResolver.openAIPlugin, model: "gpt-5").route(id))
        XCTAssertEqual(route.endpoint.absoluteString, "https://api.openai.com/v1/chat/completions")
        XCTAssertEqual(route.wire, .chatCompletions(maxTokensKey: "max_completion_tokens"))
        XCTAssertEqual(route.apiKey, "secret-key")
    }

    func testGoogleUsesGeminisOpenAIEndpoint() throws {
        let route = try XCTUnwrap(resolver(plugin: ModelProviderResolver.googlePlugin).route(id))
        XCTAssertEqual(route.endpoint.absoluteString,
                       "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions")
        XCTAssertEqual(route.wire, .chatCompletions(maxTokensKey: "max_tokens"))
    }

    func testClaudeAPIForwardsMessagesWithoutTranslation() throws {
        let bare = try XCTUnwrap(resolver(plugin: ModelProviderResolver.claudeAPIPlugin).route(id))
        XCTAssertEqual(bare.endpoint.absoluteString, "https://api.anthropic.com/v1/messages")
        XCTAssertEqual(bare.wire, .anthropic)
        let templated = try XCTUnwrap(resolver(
            plugin: ModelProviderResolver.claudeAPIPlugin, fields: ["baseURL": "https://api.anthropic.com/v1"])
            .route(id))
        XCTAssertEqual(templated.endpoint.absoluteString, "https://api.anthropic.com/v1/messages",
                       "the template's versioned base is not versioned twice")
    }

    func testClaudeAPISubscriptionTokenIsNotAProvider() {
        XCTAssertNil(resolver(plugin: ModelProviderResolver.claudeAPIPlugin, fields: ["authMode": "bearer-oauth"])
            .route(id))
    }

    func testAConfigurationSavedBeforeTheRenameStillRoutes() throws {
        let pairs = [
            (ModelProviderResolver.legacyOpenAIPlugin, ModelProviderResolver.openAIPlugin, [String: String]()),
            (ModelProviderResolver.legacyOpenAICompatiblePlugin, ModelProviderResolver.openAICompatiblePlugin,
             ["baseURL": "https://api.groq.com/openai/v1"]),
            (ModelProviderResolver.legacyGooglePlugin, ModelProviderResolver.googlePlugin, [:]),
            (ModelProviderResolver.legacyClaudeAPIPlugin, ModelProviderResolver.claudeAPIPlugin, [:])
        ]
        for (legacy, current, fields) in pairs {
            let old = try XCTUnwrap(resolver(plugin: legacy, fields: fields).route(id), legacy)
            let new = try XCTUnwrap(resolver(plugin: current, fields: fields).route(id), current)
            XCTAssertEqual(old.endpoint, new.endpoint, legacy)
            XCTAssertEqual(old.wire, new.wire, legacy)
        }
    }

    func testUnknownPluginOrConfigurationIsNil() {
        XCTAssertNil(resolver(plugin: "com.example.plugin.other").route(id))
        XCTAssertNil(resolver(plugin: ModelProviderResolver.openAIPlugin).route(UUID()))
    }

    func testAMissingRequiredKeyIsNil() {
        XCTAssertNil(resolver(plugin: ModelProviderResolver.openAIPlugin, key: nil).route(id))
        XCTAssertNil(resolver(plugin: ModelProviderResolver.openAIPlugin, key: "  ").route(id))
    }

    func testAKeylessTemplateNeedsNoKey() throws {
        let route = try XCTUnwrap(resolver(
            plugin: ModelProviderResolver.openAICompatiblePlugin, template: "ollama",
            fields: ["baseURL": "http://localhost:11434/v1"], key: nil, keyRequired: false).route(id))
        XCTAssertNil(route.apiKey)
    }

    func testAMissingModelIsNil() {
        XCTAssertNil(resolver(plugin: ModelProviderResolver.openAIPlugin, model: "").route(id))
    }

    func testAMissingModelSaysSoAndAnUnknownIdSaysUnavailable() {
        let plugin = ModelProviderResolver.openAIPlugin
        XCTAssertEqual(failure(resolver(plugin: plugin, model: " ").resolve(id)), .noModel)
        XCTAssertEqual(failure(resolver(plugin: plugin).resolve(UUID())), .unavailable)
        XCTAssertEqual(failure(resolver(plugin: plugin, key: nil).resolve(id)), .unavailable)
        XCTAssertEqual(ProviderUnavailable.noModel.rawValue, "provider has no model")
    }

    /// Final review minor 8: plain http only to this Mac; a remote http base
    /// is refused with its reason, so the request falls back untouched.
    func testPlainHTTPIsAllowedOnlyForLoopbackHosts() throws {
        let plugin = ModelProviderResolver.openAICompatiblePlugin
        for base in ["http://localhost:11434", "http://127.0.0.1:8080/v1", "http://127.1.2.3", "http://[::1]:9000",
                     "https://llm.example.com/v1"] {
            XCTAssertNotNil(resolver(plugin: plugin, fields: ["baseURL": base]).route(id), base)
        }
        for base in ["http://llm.example.com/v1", "http://192.168.1.20:11434", "http://127.0.0.1.example.com",
                     "http://localhost.example.com"] {
            XCTAssertEqual(failure(resolver(plugin: plugin, fields: ["baseURL": base]).resolve(id)), .plainHTTP, base)
        }
        XCTAssertEqual(failure(resolver(plugin: ModelProviderResolver.claudeAPIPlugin,
                                        fields: ["baseURL": "HTTP://proxy.example.com"]).resolve(id)), .plainHTTP)
        XCTAssertEqual(ProviderUnavailable.plainHTTP.rawValue,
                       "provider uses plain http to a host other than this Mac")
    }

    func testThePrintedEndpointHasNoUserinfoOrQuery() throws {
        let route = try XCTUnwrap(resolver(
            plugin: ModelProviderResolver.openAICompatiblePlugin,
            fields: ["baseURL": "https://user:hunter2@llm.example.com:8443/v1?api_key=sekrit"]).route(id))
        let mirrored = "\(Mirror(reflecting: route).children.map(\.value))"
        for printed in [route.description, String(reflecting: route), "\(route)", mirrored] {
            XCTAssertFalse(printed.contains("hunter2"))
            XCTAssertFalse(printed.contains("user:"))
            XCTAssertFalse(printed.contains("sekrit"))
            XCTAssertFalse(printed.contains("?"))
        }
        XCTAssertTrue(route.printableEndpoint.hasPrefix("https://llm.example.com:8443/v1"))
    }

    private func failure(_ result: Result<ProviderRoute, ProviderUnavailable>) -> ProviderUnavailable? {
        if case .failure(let reason) = result { return reason }
        return nil
    }

    func testNoPrintedFormShowsTheKey() throws {
        let route = try XCTUnwrap(resolver(plugin: ModelProviderResolver.openAIPlugin).route(id))
        XCTAssertFalse(route.description.contains("secret-key"))
        XCTAssertFalse(String(reflecting: route).contains("secret-key"))
        XCTAssertFalse(String(describing: Mirror(reflecting: route).children.map(\.value)).contains("secret-key"))
        XCTAssertFalse("\(route)".contains("secret-key"))
    }

    func testTheCatalogReadsSecretRequiredFromDescriptors() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let contents = root.appendingPathComponent("Compat.aiplugin/Contents")
        let resources = contents.appendingPathComponent("Resources")
        try FileManager.default.createDirectory(at: resources, withIntermediateDirectories: true)
        let plist: [String: Any] = [
            "CFBundleIdentifier": "test.compat", "CFBundlePackageType": "BNDL",
            AIPluginABI.infoPlistKey: AIPluginABI.version
        ]
        try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
            .write(to: contents.appendingPathComponent("Info.plist"))
        let descriptor = #"""
        {"schemaVersion":3,"identifier":"com.mikefullerton.agenticdeveloperhubsdk.plugin.openai-compatible",
         "displayName":"Compat","version":"1.0","models":[],"fields":[],"templates":[
          {"id":"ollama","displayName":"Ollama","defaultValues":{},"models":[],"secretRequired":false},
          {"id":"groq","displayName":"Groq","defaultValues":{},"models":[],"secretRequired":true}]}
        """#
        try Data(descriptor.utf8).write(to: resources.appendingPathComponent("descriptor.json"))
        let catalog = ProviderTemplateCatalog(searchPaths: { [root] })
        let plugin = ModelProviderResolver.openAICompatiblePlugin
        XCTAssertFalse(catalog.secretRequired(plugin: plugin, template: "ollama"))
        XCTAssertTrue(catalog.secretRequired(plugin: plugin, template: "groq"))
        XCTAssertTrue(catalog.secretRequired(plugin: plugin, template: "unknown"), "unknown requires a key")
    }
}
