import Foundation
import Testing
@testable import AgenticDeveloperHubSDKSemanticSearch

struct SearchFusionTests {

    private struct Hit: Equatable {
        let doc: String
        let from: String
    }

    private func hits(_ docs: [String], from: String) -> [Hit] {
        docs.map { Hit(doc: $0, from: from) }
    }

    @Test func mergeRankedPutsSemanticFirstThenNewKeywordHits() {
        let merged = SearchFusion.mergeRanked(
            semantic: hits(["a", "b"], from: "semantic"),
            keyword: hits(["c", "a", "d"], from: "keyword"),
            limit: 10
        ) { $0.doc }
        #expect(merged.map(\.doc) == ["a", "b", "c", "d"])
    }

    @Test func mergeRankedKeepsTheSemanticHitForADuplicate() {
        let merged = SearchFusion.mergeRanked(
            semantic: hits(["a"], from: "semantic"), keyword: hits(["a"], from: "keyword"), limit: 10
        ) { $0.doc }
        #expect(merged == [Hit(doc: "a", from: "semantic")])
    }

    @Test func mergeRankedCapsAtTheLimit() {
        let merged = SearchFusion.mergeRanked(
            semantic: hits(["a", "b", "c"], from: "semantic"), keyword: hits(["d", "e"], from: "keyword"), limit: 4
        ) { $0.doc }
        #expect(merged.map(\.doc) == ["a", "b", "c", "d"])
    }

    @Test func mergeRankedDedupesWithinAList() {
        let merged = SearchFusion.mergeRanked(
            semantic: hits(["a", "a", "b"], from: "semantic"),
            keyword: hits(["b", "c", "c"], from: "keyword"),
            limit: 10
        ) { $0.doc }
        #expect(merged.map(\.doc) == ["a", "b", "c"])
    }

    @Test func mergeRankedHandlesEmptyLists() {
        #expect(SearchFusion.mergeRanked(semantic: [Hit](), keyword: [], limit: 5) { $0.doc }.isEmpty)
        let keywordOnly = SearchFusion.mergeRanked(
            semantic: [], keyword: hits(["x"], from: "keyword"), limit: 5
        ) { $0.doc }
        #expect(keywordOnly.map(\.doc) == ["x"])
    }

    @Test func rrfRefusesShortLists() {
        #expect(throws: SearchFusionError.listTooShortForRRF(limit: 10)) {
            try SearchFusion.reciprocalRankFusion([hits(["a"], from: "s")], limit: 10) { $0.doc }
        }
    }

    @Test func rrfRanksAKeyInBothListsAboveOneInOne() throws {
        let fused = try SearchFusion.reciprocalRankFusion(
            [hits(["a", "b", "c"], from: "semantic"), hits(["c", "d"], from: "keyword")], limit: 20
        ) { $0.doc }
        // c: 1/63 + 1/61 beats a: 1/61; then b 1/62, d 1/62 (b seen first).
        #expect(fused.map(\.doc) == ["c", "a", "b", "d"])
        #expect(fused.first == Hit(doc: "c", from: "semantic"))
    }

    @Test func rrfCountsAKeyOncePerListAtItsBestRank() throws {
        let fused = try SearchFusion.reciprocalRankFusion(
            [hits(["a", "b", "a"], from: "s"), hits(["b"], from: "k")], limit: 11
        ) { $0.doc }
        #expect(fused.map(\.doc) == ["b", "a"])
    }

    @Test func rrfCapsAtTheLimit() throws {
        let docs = (0..<30).map { "d\($0)" }
        let fused = try SearchFusion.reciprocalRankFusion([hits(docs, from: "s")], limit: 12) { $0.doc }
        #expect(fused.map(\.doc) == Array(docs.prefix(12)))
    }

    @Test func searchModeRawValuesMatchTheServer() {
        #expect(SearchMode.allCases.map(\.rawValue) == ["keyword", "semantic", "combined"])
    }
}
