import Foundation
import Testing
import AIPluginKit
@testable import AgenticDeveloperHubSDKMacOS

@Suite("ModelPickerItem")
@MainActor
struct ModelPickerItemTests {

    @Test("capabilities joins tool support and strengths")
    func capabilitiesFull() {
        let item = ModelPickerItem(id: "sonnet", description: "Balanced default.",
                                   tools: true, goodFor: "Everyday tasks")
        #expect(item.capabilities == "Tools: Yes · Good for: Everyday tasks")
    }

    @Test("capabilities reports no tool support")
    func capabilitiesNoTools() {
        let item = ModelPickerItem(id: "m", tools: false, goodFor: "Text")
        #expect(item.capabilities == "Tools: No · Good for: Text")
    }

    @Test("capabilities omits blank strengths")
    func capabilitiesBlankGoodFor() {
        let item = ModelPickerItem(id: "m", tools: true, goodFor: "")
        #expect(item.capabilities == "Tools: Yes")
    }

    @Test("capabilities is nil when nothing is known")
    func capabilitiesEmpty() {
        #expect(ModelPickerItem(id: "m").capabilities == nil)
    }

    @Test("matches the title or the id, in order and case-sensitively")
    func matchingFields() {
        let item = ModelPickerItem(
            id: "claude-opus-5-5", title: "Opus 5.5",
            info: AIModelCatalog.ResolvedModel(
                id: "claude-opus-5-5", description: "Most capable.", goodFor: "Hard reasoning", tools: true))
        #expect(item.matches("Opus"))               // title
        #expect(item.matches("claude"))             // id
        #expect(item.matches("cop55"))              // scattered letters, in order, in the id
        #expect(item.matches("OPUS") == false)      // case-sensitive
        #expect(item.matches("capable") == false)   // the description isn't searched
        #expect(item.matches("reasoning") == false) // nor the strengths
        #expect(item.matches("gpt") == false)
    }

    @Test("the row shows the id when only the id matched")
    func rowTextFollowsTheMatch() {
        let item = ModelPickerItem(
            id: "claude-opus-5-5", title: "Opus 5.5",
            info: AIModelCatalog.ResolvedModel(id: "claude-opus-5-5"))
        #expect(item.rowText(for: "") == "Opus 5.5")
        #expect(item.rowText(for: "Op") == "Opus 5.5")
        #expect(item.rowText(for: "claude") == "claude-opus-5-5")
    }

    @Test("matches ignores tool support text")
    func matchingIgnoresTools() {
        // "Tools:" is rendered, not part of the searchable fields.
        let item = ModelPickerItem(id: "m", tools: true)
        #expect(item.matches("tools") == false)
    }

    @Test("a row carries the resolved catalog facts whole")
    func carriesResolvedFacts() {
        // The row stores what the catalog resolved rather than copying fields out,
        // so the numbers the detail pane shows can't drift from the table.
        let info = AIModelCatalog.ResolvedModel(
            id: "m", description: "Shared blurb.", capabilities: ["tools"],
            goodFor: "Long context", tools: true, contextWindow: 131_072,
            inputCostPerM: 0.15)
        let item = ModelPickerItem(id: "m", info: info)
        #expect(item.description == "Shared blurb.")
        #expect(item.tools == true)
        #expect(item.goodFor == "Long context")
        #expect(item.info.contextWindow == 131_072)
    }
}
