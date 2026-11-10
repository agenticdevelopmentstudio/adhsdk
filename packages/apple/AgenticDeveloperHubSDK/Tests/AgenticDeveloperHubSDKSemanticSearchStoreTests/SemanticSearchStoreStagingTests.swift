import Foundation
import GRDB
import Testing
import AgenticDeveloperHubSDKDatabase
import AgenticDeveloperHubSDKSemanticSearch
@testable import AgenticDeveloperHubSDKSemanticSearchStore

/// The synchronous staging half of the store: what a sync pull calls inside
/// its own transaction, and the filter a search runs under.
struct SemanticSearchStoreStagingTests {

    private func makeStore(embedder: (any TextEmbedder)? = FakeEmbedder()) throws -> SemanticSearchStore {
        try SemanticSearchStore(database: BoundedDatabase(path: ":memory:"), embedder: embedder)
    }

    @Test func aStagedDocumentIsKeywordSearchableBeforeAnythingIsEmbedded() async throws {
        let embedder = FakeEmbedder()
        let store = try makeStore(embedder: embedder)
        let staged = try store.database.write { conn in
            try store.stageDocument(in: conn, documentID: "d1", title: "Garage", content: "the automobile needs oil")
        }
        #expect(staged.result == .indexed(passages: 1))
        #expect(staged.awaitingVector.count == 1)
        #expect(embedder.embedCount == 0)
        #expect(try store.pendingCount() == 1)
        let hits = try await store.search("oil", mode: .keyword)
        #expect(hits.map(\.documentID) == ["d1"])
        // Semantic mode has nothing to compare yet.
        #expect(try await store.search("vehicle", mode: .semantic).isEmpty)
        #expect(try await store.embedPending() == 1)
        #expect(try await store.search("vehicle", mode: .semantic).map(\.documentID) == ["d1"])
    }

    @Test func aVectorComputedForReplacedTextIsNotStoredOnTheReusedRowid() throws {
        let embedder = FakeEmbedder()
        let store = try makeStore(embedder: embedder)
        let first = try store.database.write { conn in
            try store.stageDocument(in: conn, documentID: "d1", title: "T", content: "the automobile needs oil")
        }
        let old = try #require(first.awaitingVector.first)
        // The document changes while `old` is being embedded; its replacement takes the freed rowid.
        let second = try store.database.write { conn in
            try store.stageDocument(in: conn, documentID: "d1", title: "T", content: "a recipe for sourdough")
        }
        #expect(second.awaitingVector.first?.id == old.id)
        try store.database.write { conn in
            try VectorIndex.storeComputed(conn, passageID: old.id, title: "T", content: old.content,
                                          stamp: embedder.stamp, vector: embedder.vector(old.content))
        }
        #expect(try store.pendingCount() == 1, "the new text still needs its own vector")
    }

    @Test func aVectorWithTheEmbeddersStampIsKeptAndNeedsNoEmbedding() async throws {
        let embedder = FakeEmbedder()
        let store = try makeStore(embedder: embedder)
        let text = "the automobile needs oil"
        let vector = StagedVector(embedding: embedder.vector(text), stamp: embedder.stamp)
        let staged = try store.database.write { conn in
            try store.stageDocument(in: conn, documentID: "d1", title: nil, content: text, vector: vector)
        }
        #expect(staged.awaitingVector.isEmpty)
        #expect(try store.pendingCount() == 0)
        #expect(try await store.search("vehicle", mode: .semantic).map(\.documentID) == ["d1"])
        #expect(embedder.embedCount == 1, "only the query was embedded")
    }

    @Test func aVectorWithAnotherStampIsNeverComparedAndIsEmbeddedAgain() async throws {
        let embedder = FakeEmbedder()
        let store = try makeStore(embedder: embedder)
        let text = "the automobile needs oil"
        // A vector that would match "vehicle" perfectly, from some other model.
        let foreign = StagedVector(embedding: embedder.vector("vehicle"), stamp: "other:aaaaaaaaaaaa:bbbbbbbbbbbb:64")
        let staged = try store.database.write { conn in
            try store.stageDocument(in: conn, documentID: "d1", title: nil, content: text, vector: foreign)
        }
        #expect(staged.awaitingVector.count == 1)
        #expect(try store.pendingCount() == 1)
        #expect(try await store.search("vehicle", mode: .semantic).isEmpty)
        #expect(try await store.search("oil", mode: .keyword).map(\.documentID) == ["d1"])
        #expect(try await store.embedPending() == 1)
        let stamps = try store.database.read { conn in
            try String.fetchAll(conn, sql: "SELECT semantic_stamp FROM semantic_vectors")
        }
        #expect(stamps == [embedder.stamp])
    }

    @Test func isCurrentIsTrueOnlyForTheTextThatWasStaged() throws {
        let store = try makeStore()
        try store.database.write { conn in
            try store.stageDocument(in: conn, documentID: "d1", title: "T", content: "same text")
        }
        let answers = try store.database.read { conn in
            [try store.isCurrent(in: conn, documentID: "d1", title: "T", content: "same text"),
             try store.isCurrent(in: conn, documentID: "d1", title: "T", content: "other text"),
             try store.isCurrent(in: conn, documentID: "d1", title: nil, content: "same text"),
             try store.isCurrent(in: conn, documentID: "d2", title: "T", content: "same text")]
        }
        #expect(answers == [true, false, false, false])
    }

    @Test func aFilterKeepsSearchInsideItsSliceAndLimitCountsOnlyTheSlice() async throws {
        let store = try makeStore()
        try store.database.write { conn in
            try conn.execute(sql: "CREATE TABLE owners (id TEXT PRIMARY KEY, owner TEXT)")
            for (id, owner) in [("a1", "a"), ("a2", "a"), ("b1", "b")] {
                try conn.execute(sql: "INSERT INTO owners VALUES (?, ?)", arguments: [id, owner])
                try store.stageDocument(in: conn, documentID: id, title: nil, content: "shared words here")
            }
        }
        let onlyB = SemanticSearchFilter(documentIDsSQL: "SELECT id FROM owners WHERE owner = ?", arguments: ["b"])
        let onlyA = SemanticSearchFilter(documentIDsSQL: "SELECT id FROM owners WHERE owner = ?", arguments: ["a"])
        #expect(try await store.search("shared", mode: .keyword, filter: onlyB).map(\.documentID) == ["b1"])
        #expect(try await store.search("shared", mode: .keyword, limit: 1, filter: onlyA).count == 1)
        #expect(try await store.search("shared", mode: .keyword).count == 3)
        try await store.embedPending()
        #expect(try await store.search("shared words", mode: .semantic, filter: onlyB).map(\.documentID) == ["b1"])
        #expect(try await store.search("shared words", mode: .combined, filter: onlyB).map(\.documentID) == ["b1"])
    }

    @Test func removingADocumentOnAConnectionForgetsItsPassagesAndVectors() async throws {
        let store = try makeStore()
        try await store.indexDeviceDocument(documentID: "d1", title: nil, content: "alpha beta")
        try await store.indexDeviceDocument(documentID: "d2", title: nil, content: "alpha gamma")
        try store.database.write { conn in try store.removeDocument(in: conn, documentID: "d1") }
        #expect(try await store.search("alpha", mode: .keyword).map(\.documentID) == ["d2"])
        try store.database.write { conn in try store.removeAllDocuments(in: conn) }
        #expect(try await store.search("alpha", mode: .keyword).isEmpty)
        let vectors = try store.database.read { conn in
            try Int.fetchOne(conn, sql: "SELECT count(*) FROM semantic_vectors") ?? 0
        }
        #expect(vectors == 0)
    }

    @Test func serverPassagesApplyInsideTheCallersTransaction() async throws {
        let embedder = FakeEmbedder()
        let store = try makeStore(embedder: embedder)
        let vector = try await embedder.embed("alpha one", task: .document(title: "T"))
        let result = try store.database.write { conn in
            try conn.execute(sql: "CREATE TABLE sibling (id TEXT)")
            try conn.execute(sql: "INSERT INTO sibling VALUES ('x')")
            return try store.applyServerPassages(
                in: conn, documentID: "doc", title: "T", sourceHash: "h1",
                passages: [ServerPassage(chunkIndex: 0, content: "alpha one", embedding: vector,
                                         semanticStamp: embedder.stamp),
                           ServerPassage(chunkIndex: 1, content: "beta two")])
        }
        #expect(result == .applied)
        #expect(try await store.search("beta", mode: .keyword).map(\.documentID) == ["doc"])
        // Only the passage that came without a vector is left to embed.
        #expect(try store.pendingCount() == 1)
        let stale = try store.database.write { conn in
            try store.applyServerPassages(in: conn, documentID: "doc", title: "T", sourceHash: "h0", passages: [])
        }
        #expect(stale == .ignoredStale(currentSourceHash: "h1"))
    }
}
