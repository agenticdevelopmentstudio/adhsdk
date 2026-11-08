import Foundation
import GRDB
import Testing
import AgenticDeveloperHubSDKDatabase
import AgenticDeveloperHubSDKSemanticSearch
@testable import AgenticDeveloperHubSDKSemanticSearchStore

struct SemanticSearchStoreTests {

    private func makeStore(embedder: (any TextEmbedder)? = FakeEmbedder()) throws -> SemanticSearchStore {
        try SemanticSearchStore(database: BoundedDatabase(path: ":memory:"), embedder: embedder)
    }

    private func count(_ store: SemanticSearchStore, _ sql: String) throws -> Int {
        try store.database.read { conn in try Int.fetchOne(conn, sql: sql) ?? 0 }
    }

    // MARK: - Schema

    @Test func schemaCreationIsIdempotent() throws {
        let database = try BoundedDatabase(path: ":memory:")
        _ = try SemanticSearchStore(database: database, embedder: nil)
        _ = try SemanticSearchStore(database: database, embedder: nil)
        let tables = try database.read { conn in
            try String.fetchAll(
                conn, sql: "SELECT name FROM sqlite_master WHERE name LIKE 'semantic_%' AND type = 'table'")
        }
        #expect(Set(tables).isSuperset(of: ["semantic_documents", "semantic_passages", "semantic_vectors",
                                            "semantic_passages_fts"]))
    }

    // MARK: - Indexing

    @Test func indexingADeviceDocumentMakesEmbeddedDevicePassages() async throws {
        let embedder = FakeEmbedder()
        let store = try makeStore(embedder: embedder)
        let content = "# Coast\n\nWe drove to the coast.\n\n# Hills\n\nThen the hills."
        let result = try await store.indexDeviceDocument(documentID: "d1", title: "Trip", content: content)
        #expect(result == .indexed(passages: 2))
        #expect(try count(store, "SELECT count(*) FROM semantic_passages WHERE origin = 'device'") == 2)
        #expect(try count(store, "SELECT count(*) FROM semantic_vectors") == 2)
        #expect(embedder.embedCount == 2)
        #expect(try store.pendingCount() == 0)
        let hash = try store.database.read { conn in
            try String.fetchOne(conn, sql: "SELECT DISTINCT source_hash FROM semantic_passages")
        }
        #expect(hash == PassageSourceHash.of(title: "Trip", content: content))
    }

    @Test func vectorsAreStoredAsHalfFloatsWithTheStamp() async throws {
        let embedder = FakeEmbedder()
        let store = try makeStore(embedder: embedder)
        try await store.indexDeviceDocument(documentID: "d1", title: nil, content: "car engine")
        let row = try #require(try store.database.read { conn in
            try Row.fetchOne(conn, sql: "SELECT semantic_stamp, embedding FROM semantic_vectors")
        })
        #expect((row["semantic_stamp"] as String) == embedder.stamp)
        let blob: Data = row["embedding"]
        #expect(blob.count == embedder.dimensions * 2)
        let decoded = try HalfVectorCodec.decode(blob, dimensions: embedder.dimensions)
        #expect(VectorMath.cosine(decoded, embedder.vector("car engine")) > 0.9999)
    }

    @Test func reindexingReplacesTheOldPassages() async throws {
        let store = try makeStore()
        try await store.indexDeviceDocument(documentID: "d1", title: nil, content: "giraffe facts")
        try await store.indexDeviceDocument(documentID: "d1", title: nil, content: "penguin facts")
        #expect(try await store.search("giraffe", mode: .keyword).isEmpty)
        #expect(try await store.search("penguin", mode: .keyword).map(\.documentID) == ["d1"])
        #expect(try count(store, "SELECT count(*) FROM semantic_passages") == 1)
        #expect(try count(store, "SELECT count(*) FROM semantic_vectors") == 1)
    }

    @Test func indexingWithoutAnEmbedderLeavesPassagesPending() async throws {
        let store = try makeStore(embedder: nil)
        let result = try await store.indexDeviceDocument(documentID: "d1", title: nil, content: "words here")
        #expect(result == .indexed(passages: 1))
        #expect(try count(store, "SELECT count(*) FROM semantic_vectors") == 0)
        #expect(try store.pendingCount() == 0)
        #expect(try await store.embedPending() == 0)
    }

    @Test func removingADocumentRemovesEverything() async throws {
        let store = try makeStore()
        try await store.indexDeviceDocument(documentID: "d1", title: "T", content: "alpha\n\n# B\n\nbeta")
        try store.removeDocument(documentID: "d1")
        for table in ["semantic_documents", "semantic_passages", "semantic_vectors"] {
            #expect(try count(store, "SELECT count(*) FROM \(table)") == 0)
        }
        #expect(try await store.search("alpha", mode: .keyword).isEmpty)
    }

    // MARK: - Keyword

    @Test func keywordSearchFindsWordsAndReportsNoSimilarity() async throws {
        let store = try makeStore()
        try await store.indexDeviceDocument(documentID: "d1", title: "Passwords", content: "How to reset a password.")
        try await store.indexDeviceDocument(documentID: "d2", title: "Lunch", content: "Soup and bread.")
        let hits = try await store.search("reset password", mode: .keyword)
        #expect(hits.map(\.documentID) == ["d1"])
        #expect(hits.first?.similarity == nil)
        #expect(hits.first?.isDeviceMade == true)
        #expect(hits.first?.title == "Passwords")
    }

    @Test func keywordSearchNeedsEveryWord() async throws {
        let store = try makeStore()
        try await store.indexDeviceDocument(documentID: "d1", title: nil, content: "red apple")
        try await store.indexDeviceDocument(documentID: "d2", title: nil, content: "green apple")
        #expect(try await store.search("apple", mode: .keyword).count == 2)
        #expect(try await store.search("red apple", mode: .keyword).map(\.documentID) == ["d1"])
        #expect(try await store.search("blue apple", mode: .keyword).isEmpty)
    }

    @Test func keywordSearchMatchesTitlesFoldsCaseAndDiacritics() async throws {
        let store = try makeStore()
        try await store.indexDeviceDocument(documentID: "d1", title: "Café Notes", content: "opening hours")
        #expect(try await store.search("CAFE", mode: .keyword).map(\.documentID) == ["d1"])
    }

    @Test func keywordSearchTakesOperatorsAsWords() async throws {
        let store = try makeStore()
        try await store.indexDeviceDocument(documentID: "d1", title: nil, content: "near or not")
        #expect(try await store.search("NEAR OR", mode: .keyword).map(\.documentID) == ["d1"])
        #expect(try await store.search("\"unbalanced * ^col: (", mode: .keyword).isEmpty)
        #expect(try await store.search("   ", mode: .keyword).isEmpty)
        #expect(try await store.search("- ...", mode: .keyword).isEmpty)
        #expect(KeywordIndex.matchExpression(for: "say \"hi\" now") == "\"say\" \"\"\"hi\"\"\" \"now\"")
    }

    @Test func keywordSearchReturnsTheBestPassagePerDocument() async throws {
        let store = try makeStore()
        let content = "# One\n\nzebra mentioned once.\n\n# Two\n\nzebra zebra zebra, a whole passage on the zebra."
        try await store.indexDeviceDocument(documentID: "d1", title: nil, content: content)
        let hits = try await store.search("zebra", mode: .keyword)
        #expect(hits.count == 1)
        #expect(hits.first?.chunkIndex == 1)
    }

    // MARK: - Semantic

    @Test func semanticSearchFindsMeaningWithoutSharedWords() async throws {
        let store = try makeStore()
        try await store.indexDeviceDocument(documentID: "cars", title: nil, content: "car")
        try await store.indexDeviceDocument(documentID: "soup", title: nil, content: "tomato soup recipe")
        #expect(try await store.search("automobile", mode: .keyword).isEmpty)
        let hits = try await store.search("automobile", mode: .semantic, limit: 1)
        #expect(hits.map(\.documentID) == ["cars"])
        let similarity = try #require(hits.first?.similarity)
        #expect(similarity > 0.99)
    }

    @Test func semanticSearchRanksByCosineOnePerDocument() async throws {
        let store = try makeStore()
        try await store.indexDeviceDocument(documentID: "near", title: nil, content: "garden flowers")
        try await store.indexDeviceDocument(documentID: "exact", title: nil, content: "garden flowers bloom")
        try await store.indexDeviceDocument(
            documentID: "split", title: nil, content: "# A\n\nunrelated words\n\n# B\n\ngarden flowers bloom")
        let hits = try await store.search("garden flowers bloom", mode: .semantic)
        #expect(hits.count == 3)
        #expect(Set(hits.prefix(2).map(\.documentID)) == ["exact", "split"])
        #expect(hits.last?.documentID == "near")
        #expect(hits.first(where: { $0.documentID == "split" })?.chunkIndex == 1)
        let scores = hits.compactMap(\.similarity)
        #expect(scores == scores.sorted(by: >))
    }

    @Test func semanticSearchIgnoresVectorsFromAnotherModel() async throws {
        let database = try BoundedDatabase(path: ":memory:")
        let oldEmbedder = FakeEmbedder(stamp: "old:000000000000:000000000000:64")
        let old = try SemanticSearchStore(database: database, embedder: oldEmbedder)
        try await old.indexDeviceDocument(documentID: "d1", title: nil, content: "car")
        let current = try SemanticSearchStore(database: database, embedder: FakeEmbedder())
        #expect(try await current.search("car", mode: .semantic).isEmpty)
        #expect(try current.pendingCount() == 1)
        #expect(try await current.embedPending() == 1)
        #expect(try await current.search("car", mode: .semantic).map(\.documentID) == ["d1"])
    }

    @Test func semanticSearchWithoutAnEmbedderThrows() async throws {
        let store = try makeStore(embedder: nil)
        await #expect(throws: SemanticSearchStoreError.noEmbedder) {
            try await store.search("anything", mode: .semantic)
        }
    }

    // MARK: - Combined

    @Test func combinedPutsSemanticHitsFirstThenNewKeywordHits() async throws {
        let store = try makeStore()
        // "sem" matches the query only by meaning; "both" by meaning and word;
        // "kw" only by word, since it synced down with no vector yet.
        try await store.indexDeviceDocument(documentID: "sem", title: nil, content: "car")
        try await store.indexDeviceDocument(documentID: "both", title: nil, content: "automobile")
        try store.applyServerPassages(documentID: "kw", title: nil, sourceHash: "h",
                                      passages: [ServerPassage(chunkIndex: 0, content: "automobile parts")])
        let semantic = try await store.search("automobile", mode: .semantic, limit: 3)
        let keyword = try await store.search("automobile", mode: .keyword, limit: 3)
        let combined = try await store.search("automobile", mode: .combined, limit: 3)
        #expect(Set(semantic.map(\.documentID)) == ["sem", "both"])
        #expect(Set(keyword.map(\.documentID)) == ["both", "kw"])
        #expect(Array(combined.prefix(2).map(\.documentID)) == semantic.map(\.documentID))
        // Capped: a limit of 2 is the semantic hits alone.
        let capped = try await store.search("automobile", mode: .combined, limit: 2)
        #expect(capped.map(\.documentID) == semantic.map(\.documentID))
        #expect(combined.map(\.documentID).last == "kw")
        #expect(combined.count == 3)
        // The semantic hit wins the dedupe, so "both" carries a similarity.
        #expect(combined.first(where: { $0.documentID == "both" })?.similarity != nil)
        #expect(combined.last?.similarity == nil)
    }

    @Test func combinedWithoutAnEmbedderIsKeywordOnly() async throws {
        let store = try makeStore(embedder: nil)
        try await store.indexDeviceDocument(documentID: "d1", title: nil, content: "plain words")
        let hits = try await store.search("words", mode: .combined)
        #expect(hits.map(\.documentID) == ["d1"])
        #expect(hits.first?.similarity == nil)
    }

    @Test func combinedRRFIsOnlyForLongLists() async throws {
        let store = try makeStore()
        try await store.indexDeviceDocument(documentID: "d1", title: nil, content: "car")
        await #expect(throws: SearchFusionError.listTooShortForRRF(limit: 10)) {
            try await store.search("car", mode: .combined, limit: 10, fusion: .reciprocalRank)
        }
        let hits = try await store.search("car", mode: .combined, limit: 20, fusion: .reciprocalRank)
        #expect(hits.map(\.documentID) == ["d1"])
    }

    // MARK: - Device and server passages

    @Test func serverPassagesReplaceDevicePassagesForTheSameText() async throws {
        let store = try makeStore()
        let content = "The server will split this too."
        try await store.indexDeviceDocument(documentID: "d1", title: "T", content: content)
        let hash = PassageSourceHash.of(title: "T", content: content)
        let result = try store.applyServerPassages(
            documentID: "d1", title: "T", sourceHash: hash,
            passages: [ServerPassage(chunkIndex: 0, content: content)])
        #expect(result == .applied)
        #expect(try count(store, "SELECT count(*) FROM semantic_passages WHERE origin = 'device'") == 0)
        #expect(try count(store, "SELECT count(*) FROM semantic_passages WHERE origin = 'server'") == 1)
        let hits = try await store.search("server split", mode: .keyword)
        #expect(hits.map(\.isDeviceMade) == [false])
    }

    @Test func serverPassagesForOtherTextAreIgnored() async throws {
        let store = try makeStore()
        try await store.indexDeviceDocument(documentID: "d1", title: nil, content: "my newer edit")
        let result = try store.applyServerPassages(
            documentID: "d1", title: nil, sourceHash: PassageSourceHash.of(title: nil, content: "the older text"),
            passages: [ServerPassage(chunkIndex: 0, content: "the older text")])
        #expect(result == .ignoredStale(currentSourceHash: PassageSourceHash.of(title: nil, content: "my newer edit")))
        #expect(try await store.search("older", mode: .keyword).isEmpty)
        #expect(try await store.search("newer", mode: .keyword).map(\.isDeviceMade) == [true])
    }

    @Test func serverPassagesForANewDocumentApply() async throws {
        let store = try makeStore()
        let result = try store.applyServerPassages(
            documentID: "d9", title: nil, sourceHash: "abc",
            passages: [ServerPassage(chunkIndex: 0, content: "first"), ServerPassage(chunkIndex: 1, content: "second")])
        #expect(result == .applied)
        #expect(try await store.search("second", mode: .keyword).first?.chunkIndex == 1)
    }

    @Test func newerServerPassagesReplaceOlderOnes() async throws {
        let store = try makeStore()
        try store.applyServerPassages(documentID: "d1", title: nil, sourceHash: "h1",
                                      passages: [ServerPassage(chunkIndex: 0, content: "version one")])
        // The device learns the newer text from sync and indexes it first...
        try await store.indexDeviceDocument(documentID: "d1", title: nil, content: "version two")
        let hash = PassageSourceHash.of(title: nil, content: "version two")
        // ...then the server's passages for that text arrive.
        let result = try store.applyServerPassages(
            documentID: "d1", title: nil, sourceHash: hash,
            passages: [ServerPassage(chunkIndex: 0, content: "version two")])
        #expect(result == .applied)
        #expect(try await store.search("one", mode: .keyword).isEmpty)
        #expect(try await store.search("two", mode: .keyword).map(\.isDeviceMade) == [false])
    }

    @Test func indexingTextTheServerAlreadySplitKeepsTheServerPassages() async throws {
        let embedder = FakeEmbedder()
        let store = try makeStore(embedder: embedder)
        let content = "Already split by the server."
        let hash = PassageSourceHash.of(title: nil, content: content)
        try store.applyServerPassages(documentID: "d1", title: nil, sourceHash: hash,
                                      passages: [ServerPassage(chunkIndex: 0, content: content)])
        let result = try await store.indexDeviceDocument(documentID: "d1", title: nil, content: content)
        #expect(result == .serverPassagesCurrent)
        #expect(try count(store, "SELECT count(*) FROM semantic_passages WHERE origin = 'server'") == 1)
        #expect(try count(store, "SELECT count(*) FROM semantic_passages WHERE origin = 'device'") == 0)
        #expect(embedder.embedCount == 0)
    }

    @Test func aServerVectorWithTheEmbedderStampIsUsedAsIs() async throws {
        let embedder = FakeEmbedder()
        let store = try makeStore(embedder: embedder)
        try store.applyServerPassages(
            documentID: "d1", title: nil, sourceHash: "h",
            passages: [ServerPassage(chunkIndex: 0, content: "car", embedding: embedder.vector("car"),
                                     semanticStamp: embedder.stamp)])
        #expect(try store.pendingCount() == 0)
        #expect(try await store.search("car", mode: .semantic).map(\.documentID) == ["d1"])
        #expect(embedder.embedCount == 1) // the query only
    }

    @Test func aServerVectorFromAnotherModelIsEmbeddedHere() async throws {
        let embedder = FakeEmbedder()
        let store = try makeStore(embedder: embedder)
        try store.applyServerPassages(
            documentID: "d1", title: nil, sourceHash: "h",
            passages: [ServerPassage(chunkIndex: 0, content: "car", embedding: [Float](repeating: 0.125, count: 64),
                                     semanticStamp: "other:000000000000:000000000000:64")])
        #expect(try store.pendingCount() == 1)
        #expect(try await store.embedPending(limit: 10) == 1)
        #expect(try store.pendingCount() == 0)
        #expect(try await store.search("automobile", mode: .semantic).map(\.documentID) == ["d1"])
    }

    @Test func embedPendingHonoursItsLimit() async throws {
        let store = try makeStore()
        try store.applyServerPassages(
            documentID: "d1", title: nil, sourceHash: "h",
            passages: (0..<5).map { ServerPassage(chunkIndex: $0, content: "passage \($0)") })
        #expect(try store.pendingCount() == 5)
        #expect(try await store.embedPending(limit: 2) == 2)
        #expect(try store.pendingCount() == 3)
        #expect(try await store.embedPending(limit: 10) == 3)
        #expect(try await store.embedPending(limit: 10) == 0)
    }
}
