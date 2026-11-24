import Testing
@testable import AIPluginKit

@Suite("FallbackModelSource")
struct FallbackModelSourceTests {
    struct Stub: ProviderModelSource {
        let cacheKey: String
        let ids: [String]?
        func fetch() async -> ProviderModelList? { ids.map { ProviderModelList(ids: $0) } }
    }

    @Test("a fallback's answer is keyed to the source that gave it")
    func fallbackKeepsItsOwnKey() async {
        let chain = FallbackModelSource([
            Stub(cacheKey: "account", ids: nil),
            Stub(cacheKey: "catalog", ids: ["claude-opus-5-5"])
        ])
        let answer = await chain.load()
        #expect(answer?.cacheKey == "catalog")
        #expect(answer?.list.latestIDs == ["claude-opus-5-5"])
        #expect(chain.cacheKeys == ["account", "catalog"])
        #expect(chain.cacheKey == "account")
    }

    @Test("the first source that answers wins")
    func firstAnswerWins() async {
        let chain = FallbackModelSource([
            Stub(cacheKey: "account", ids: ["claude-sonnet-4-5"]),
            Stub(cacheKey: "catalog", ids: ["claude-opus-5-5"])
        ])
        #expect(await chain.load()?.cacheKey == "account")
    }

    @Test("an empty list counts as no answer")
    func emptyIsNoAnswer() async {
        let chain = FallbackModelSource([Stub(cacheKey: "account", ids: [])])
        #expect(await chain.load() == nil)
    }
}
