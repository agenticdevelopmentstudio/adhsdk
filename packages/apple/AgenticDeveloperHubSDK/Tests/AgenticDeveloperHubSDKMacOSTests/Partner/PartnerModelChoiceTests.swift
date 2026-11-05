import XCTest
import AIPluginKit
@testable import AgenticDeveloperHubSDKMacOS
@testable import AgenticDeveloperHubSDKCore

@MainActor
final class PartnerModelChoiceTests: XCTestCase {
    private let claude = AIProviderConfiguration(
        name: "Claude", pluginIdentifier: PartnerModelChoice.claudeLocalPluginIdentifier, templateId: "claude-local")
    private let ollama = AIProviderConfiguration(
        name: "Ollama",
        pluginIdentifier: "com.mikefullerton.agenticdeveloperhubsdk.plugin.ollama",
        templateId: "ollama"
    )

    private func resolve(_ provider: String, legacy: String = "") -> Result<String, PartnerModelChoice.Failure> {
        PartnerModelChoice.resolve(provider: provider, configurations: [claude, ollama],
                                   model: { $0 == self.claude.id ? "claude-opus-5-5" : "other" },
                                   legacyModel: legacy)
    }

    func testDefaultProviderUsesTheLegacyModel() {
        XCTAssertEqual(try resolve("", legacy: "opus").get(), "opus")
    }

    func testClaudeLocalConfigurationGivesItsModel() {
        XCTAssertEqual(try resolve(claude.id.uuidString).get(), "claude-opus-5-5")
    }

    func testAnotherPluginIsRefusedByName() {
        XCTAssertEqual(resolve(ollama.id.uuidString), .failure(.notClaudeCode("Ollama")))
        XCTAssertEqual(PartnerModelChoice.Failure.notClaudeCode("Ollama").message,
                       "The Coding Partner runs on a Claude Code provider; Ollama is not one.")
    }

    func testAMissingConfigurationIsUnknown() {
        XCTAssertEqual(resolve(UUID().uuidString), .failure(.unknownProvider))
        XCTAssertEqual(PartnerModelChoice.Failure.unknownProvider.message,
                       "The Coding Partner's provider is no longer configured.")
    }

    // MARK: - Allowed tools

    func testSplitKeepsParenthesisedEntriesWhole() {
        XCTAssertEqual(UserSettings.splitAllowedTools("Read Bash(npm run *) mcp__x"),
                       ["Read", "Bash(npm run *)", "mcp__x"])
        XCTAssertEqual(UserSettings.splitAllowedTools(UserSettings.partnerAllowedToolsLegacyDefaults[0]),
                       UserSettings.partnerAllowedToolsList.defaultValue)
    }

    func testMigrationMovesAnEditedStringAndRemovesTheOldKey() {
        let settings = SettingsStore(with: InMemorySettingsStorageProvider(),
                                     secureSettingsProvider: InMemorySecureSettingsStorageProvider())
        settings.set("Read Edit", for: UserSettings.partnerAllowedToolsLegacy)
        UserSettings.migratePartnerAllowedToolsToList(in: settings)
        XCTAssertEqual(settings.get(UserSettings.partnerAllowedToolsList), ["Read", "Edit"])
        XCTAssertFalse(settings.contains(UserSettings.partnerAllowedToolsLegacy))
    }

    func testMigrationWritesNothingForEitherOldDefault() {
        for old in UserSettings.partnerAllowedToolsLegacyDefaults {
            let settings = SettingsStore(with: InMemorySettingsStorageProvider(),
                                         secureSettingsProvider: InMemorySecureSettingsStorageProvider())
            settings.set(old, for: UserSettings.partnerAllowedToolsLegacy)
            UserSettings.migratePartnerAllowedToolsToList(in: settings)
            XCTAssertFalse(settings.contains(UserSettings.partnerAllowedToolsList))
            XCTAssertFalse(settings.contains(UserSettings.partnerAllowedToolsLegacy))
        }
    }
}
