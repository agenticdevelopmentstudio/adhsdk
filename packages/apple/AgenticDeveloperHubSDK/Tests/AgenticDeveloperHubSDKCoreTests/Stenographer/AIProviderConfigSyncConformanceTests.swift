import XCTest
@testable import AgenticDeveloperHubSDKCore

final class AIProviderConfigSyncConformanceTests: XCTestCase {

    private func makeConfig(secrets: [String: String] = ["apiKey": "sk-abc"]) -> ResolvedProviderConfig {
        ResolvedProviderConfig(
            id: UUID(), name: "Groq", pluginIdentifier: "com.x.openai-compatible",
            templateId: "custom", model: "llama",
            values: ["baseURL": "https://api.groq.com/openai/v1"], secrets: secrets)
    }

    private func jsonObject(_ value: some Encodable) throws -> [String: Any] {
        let data = try JSONEncoder().encode(value)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    func testV001_roundTrip() throws {
        let config = makeConfig()
        let sync = AIProviderConfigSync(enabled: true, selectedConfigId: config.id, configs: [config])
        let data = try JSONEncoder().encode(sync)
        XCTAssertEqual(try JSONDecoder().decode(AIProviderConfigSync.self, from: data), sync)
    }

    func testV002_missingSelectionDecodesAsNil() throws {
        let data = Data(#"{"enabled":false,"configs":[]}"#.utf8)
        let decoded = try JSONDecoder().decode(AIProviderConfigSync.self, from: data)
        XCTAssertNil(decoded.selectedConfigId)
        XCTAssertFalse(decoded.enabled)
        XCTAssertTrue(decoded.configs.isEmpty)
    }

    func testV003_missingRemovedConfigIdsDecodesAsNil() throws {
        let data = Data(#"{"enabled": true, "configs": []}"#.utf8)
        let decoded = try JSONDecoder().decode(AIProviderConfigSync.self, from: data)
        XCTAssertNil(decoded.removedConfigIds)
    }

    func testV004_initializerDefaultsRemovedConfigIdsToNil() {
        let sync = AIProviderConfigSync(enabled: true, selectedConfigId: nil, configs: [])
        XCTAssertNil(sync.removedConfigIds)
    }

    func testV005_emptyRemovedListEncodesAsEmptyArray() throws {
        let sync = AIProviderConfigSync(
            enabled: true, selectedConfigId: nil, configs: [], removedConfigIds: [])
        let object = try jsonObject(sync)
        let removed = try XCTUnwrap(object["removedConfigIds"] as? [Any])
        XCTAssertTrue(removed.isEmpty)
        let decoded = try JSONDecoder().decode(
            AIProviderConfigSync.self, from: try JSONEncoder().encode(sync))
        XCTAssertEqual(decoded.removedConfigIds, [])
    }

    func testV006_nonNilRemovedListSurvivesTheWire() throws {
        let removedId = UUID()
        let sync = AIProviderConfigSync(
            enabled: true, selectedConfigId: nil, configs: [makeConfig()], removedConfigIds: [removedId])
        let decoded = try JSONDecoder().decode(
            AIProviderConfigSync.self, from: try JSONEncoder().encode(sync))
        XCTAssertEqual(decoded.removedConfigIds, [removedId])
        XCTAssertEqual(decoded.configs.count, 1)
    }

    func testV007_nilRemovedListLeavesTheKeyOutOfTheWire() throws {
        let sync = AIProviderConfigSync(enabled: true, selectedConfigId: nil, configs: [makeConfig()])
        let object = try jsonObject(sync)
        XCTAssertNil(object["removedConfigIds"])
        XCTAssertEqual((object["configs"] as? [Any])?.count, 1)
    }

    func testV008_missingEnabledThrowsKeyNotFound() {
        let data = Data(#"{"configs":[]}"#.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(AIProviderConfigSync.self, from: data)) { error in
            guard case DecodingError.keyNotFound(let key, _) = error else {
                return XCTFail("expected keyNotFound, got \(error)")
            }
            XCTAssertEqual(key.stringValue, "enabled")
        }
    }

    func testV009_emptySecretIsPreservedOnTheWire() throws {
        let config = makeConfig(secrets: ["apiKey": ""])
        let object = try jsonObject(config)
        let secrets = try XCTUnwrap(object["secrets"] as? [String: String])
        XCTAssertEqual(secrets["apiKey"], "")
        let decoded = try JSONDecoder().decode(
            ResolvedProviderConfig.self, from: try JSONEncoder().encode(config))
        XCTAssertEqual(decoded.secrets["apiKey"], "")
    }

    func testV010_aliasResolvesToCoreType() throws {
        throw XCTSkip("The alias lives in AIPluginKit; covered by AIPluginKitTests testRoundTrip")
    }

    func testV011_configInitializerRequiresValuesAndSecrets() throws {
        throw XCTSkip("Compile-time vector: omitting values or secrets does not compile; nothing to run")
    }
}
