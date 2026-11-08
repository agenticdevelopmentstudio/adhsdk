import Foundation
import Testing
@testable import AIPluginKit

/// A provider's model list: every model, the latest of each family, and the
/// parsers that build one from the Anthropic API and models.dev.
@Suite("ProviderModelList")
struct ProviderModelListTests {

    private static func model(_ id: String, _ date: String?) -> ProviderModel {
        ProviderModel(id: id, family: AnthropicModelFamily.family(of: id), releaseDate: date)
    }

    @Test("the latest version of each family, newest first")
    func latestPerFamily() {
        let list = ProviderModelList(models: [
            Self.model("claude-opus-4-8", "2026-05-28"),
            Self.model("claude-opus-5-5", "2026-09-22"),
            Self.model("claude-haiku-4-5", "2025-10-15"),
            Self.model("claude-haiku-5-5", "2026-10-07"),
            Self.model("claude-fable-5-1", "2026-09-01"),
            Self.model("claude-fable-5", "2026-06-07"),
            Self.model("claude-sonnet-5-5", "2026-09-28")
        ])
        #expect(list.latestIDs == ["claude-haiku-5-5", "claude-sonnet-5-5",
                                   "claude-opus-5-5", "claude-fable-5-1"])
        #expect(list.allIDs.first == "claude-haiku-5-5")
        #expect(list.allIDs.count == 7)
        #expect(list.hasOlderVersions)
    }

    @Test("an alias beats its dated snapshot on the same date")
    func aliasBeatsSnapshot() {
        let list = ProviderModelList(models: [
            Self.model("claude-haiku-4-5-20251001", "2025-10-15"),
            Self.model("claude-haiku-4-5", "2025-10-15")
        ])
        #expect(list.latestIDs == ["claude-haiku-4-5"])
    }

    @Test("models without a family are all kept")
    func unknownFamilyKept() {
        let list = ProviderModelList(ids: ["gpt-4o", "llama3.2"])
        #expect(list.latestIDs == ["gpt-4o", "llama3.2"])
        #expect(list.hasOlderVersions == false)
    }

    @Test("Anthropic family across both naming eras")
    func anthropicFamily() {
        #expect(AnthropicModelFamily.family(of: "claude-opus-5-5") == "claude-opus")
        #expect(AnthropicModelFamily.family(of: "claude-haiku-4-5-20251001") == "claude-haiku")
        #expect(AnthropicModelFamily.family(of: "claude-3-5-sonnet-20241022") == "claude-sonnet")
        #expect(AnthropicModelFamily.family(of: "claude-3-haiku-20240307") == "claude-haiku")
        #expect(AnthropicModelFamily.family(of: "gpt-4o") == nil)
    }

    @Test("parses the Anthropic /v1/models body")
    func parseAnthropic() throws {
        let body = """
        {"data": [
          {"id": "claude-opus-5-5", "display_name": "Claude Opus 5.5", "created_at": "2026-09-22T00:00:00Z"},
          {"id": "claude-opus-4-8", "display_name": "Claude Opus 4.8", "created_at": "2026-05-28T00:00:00Z"}
        ]}
        """
        let list = try #require(AnthropicModelsSource.parse(Data(body.utf8)))
        #expect(list.latestIDs == ["claude-opus-5-5"])
        #expect(list.models.first?.displayName == "Claude Opus 5.5")
        #expect(list.models.first?.releaseDate == "2026-09-22")
    }

    @Test("parses one provider out of the models.dev catalog")
    func parseModelsDev() throws {
        let body = """
        {"anthropic": {"models": {
          "claude-sonnet-5-5": {"name": "Claude Sonnet 5.5", "family": "claude-sonnet", "release_date": "2026-09-28"},
          "claude-sonnet-4-5": {"name": "Claude Sonnet 4.5", "family": "claude-sonnet", "release_date": "2025-09-29"},
          "claude-sonnet-4-5-20250929": {"name": "Claude Sonnet 4.5", "family": "claude-sonnet",
                                         "release_date": "2025-09-29"}
        }}, "openai": {"models": {}}}
        """
        let all = try #require(ModelsDevModelsSource.parse(Data(body.utf8), provider: "anthropic"))
        #expect(all.allIDs == ["claude-sonnet-5-5", "claude-sonnet-4-5", "claude-sonnet-4-5-20250929"])
        #expect(all.latestIDs == ["claude-sonnet-5-5"])
        let aliases = try #require(ModelsDevModelsSource.parse(
            Data(body.utf8), provider: "anthropic", excludeDatedSnapshots: true))
        #expect(aliases.allIDs == ["claude-sonnet-5-5", "claude-sonnet-4-5"])
        #expect(ModelsDevModelsSource.parse(Data(body.utf8), provider: "openai") == nil)
    }
}
