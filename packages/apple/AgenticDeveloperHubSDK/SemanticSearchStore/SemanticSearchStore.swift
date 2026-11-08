import Foundation
import GRDB
import AgenticDeveloperHubSDKDatabase
import AgenticDeveloperHubSDKSemanticSearch

/// One search result: the best-matching passage of one document.
public struct SemanticSearchHit: Sendable, Equatable {
    public let passageID: Int64
    public let documentID: String
    public let chunkIndex: Int
    /// The document's title, `nil` when it has none.
    public let title: String?
    public let content: String
    /// True for a passage this device made, before the server's passages for
    /// the same text arrived.
    public let isDeviceMade: Bool
    /// The cosine between the query and the passage. `nil` for a keyword
    /// hit, whose bm25 rank is not on the same scale, as on the server.
    public let similarity: Float?

    public init(passageID: Int64, documentID: String, chunkIndex: Int, title: String?, content: String,
                isDeviceMade: Bool, similarity: Float?) {
        self.passageID = passageID
        self.documentID = documentID
        self.chunkIndex = chunkIndex
        self.title = title
        self.content = content
        self.isDeviceMade = isDeviceMade
        self.similarity = similarity
    }

    init(row: Row, similarity: Float?) {
        let title: String = row["title"]
        self.init(passageID: row["id"], documentID: row["document_id"], chunkIndex: row["chunk_index"],
                  title: title.isEmpty ? nil : title, content: row["content"],
                  isDeviceMade: (row["origin"] as String) == PassageOrigin.device.rawValue,
                  similarity: similarity)
    }
}

/// Where a passage came from.
public enum PassageOrigin: String, Sendable {
    /// Made on this device so a new or edited document is searchable at once.
    /// Temporary and local: nothing pushes it, and the server's passages for
    /// the same text replace it.
    case device
    /// Made by the server's chunker and synced down.
    case server
}

/// A passage the server made, as it syncs down.
public struct ServerPassage: Sendable, Equatable {
    public let chunkIndex: Int
    public let content: String
    /// The server's vector, when it sent one, with the stamp of the model
    /// that made it. A vector whose stamp is not this device's embedder's is
    /// kept but never compared, and the passage is embedded here instead.
    public let embedding: [Float]?
    public let semanticStamp: String?

    public init(chunkIndex: Int, content: String, embedding: [Float]? = nil, semanticStamp: String? = nil) {
        precondition((embedding == nil) == (semanticStamp == nil),
                     "a vector needs its stamp, and only a vector has one")
        self.chunkIndex = chunkIndex
        self.content = content
        self.embedding = embedding
        self.semanticStamp = semanticStamp
    }
}

/// What ``SemanticSearchStore/indexDeviceDocument(documentID:title:content:)`` did.
public enum DeviceIndexResult: Sendable, Equatable {
    /// The document was split into this many device passages.
    case indexed(passages: Int)
    /// The server's passages already match this text, so they stay.
    case serverPassagesCurrent
}

/// What ``SemanticSearchStore/applyServerPassages(documentID:title:sourceHash:passages:)`` did.
public enum ServerApplyResult: Sendable, Equatable {
    /// The passages replace whatever the document had.
    case applied
    /// The device holds different text for the document (an edit the server
    /// has not seen, or one it has not sent back yet), so the passages were
    /// dropped. The device's own passages stay until text and passages agree.
    case ignoredStale(currentSourceHash: String)
}

/// How combined mode merges its two lists.
public enum CombinedFusion: Sendable, Equatable {
    /// The server's rule: semantic hits, then new keyword hits.
    case serverOrder
    /// Reciprocal Rank Fusion, offered only for a `limit` over
    /// ``SearchFusion/shortListLimit``.
    case reciprocalRank
}

public enum SemanticSearchStoreError: Error, Sendable, Equatable, CustomStringConvertible {
    /// Semantic mode needs an embedder and the store was opened without one.
    case noEmbedder

    public var description: String {
        switch self {
        case .noEmbedder: "semantic search needs an embedder; this store has none"
        }
    }
}

/// Semantic and keyword search over an app's documents, in its own SQLite
/// database, following `docs/specs/ingredients/semantic-search.md`.
///
/// A document's passages come from one of two places. ``indexDeviceDocument(documentID:title:content:)``
/// splits text saved on this device into device passages so it is searchable
/// at once. ``applyServerPassages(documentID:title:sourceHash:passages:)``
/// stores the server's passages when they sync down, and they replace the
/// device's for the same text. Which text is current is decided by source
/// hash (``PassageSourceHash``): the store keeps the hash of the text it was
/// last given and only keeps passages made from it. Device passages are never
/// pushed; the store has no way to send anything anywhere.
///
/// Without an embedder the store still indexes and keyword-searches;
/// semantic mode throws ``SemanticSearchStoreError/noEmbedder`` and combined
/// mode is keyword only. Passages saved without a vector are embedded by
/// ``embedPending(limit:)``.
public final class SemanticSearchStore: Sendable {
    public let database: BoundedDatabase
    public let embedder: (any TextEmbedder)?
    public let chunker: PassageChunker

    public init(
        database: BoundedDatabase, embedder: (any TextEmbedder)?, chunker: PassageChunker = PassageChunker()
    ) throws {
        self.database = database
        self.embedder = embedder
        self.chunker = chunker
        try database.write { conn in try SemanticSearchSchema.create(in: conn) }
    }

    // MARK: - Indexing

    /// Makes `content` searchable now. When the server's passages for exactly
    /// this text are already here they are kept; otherwise the document's
    /// passages are replaced with device passages, split to the embedder's
    /// token budget and embedded at once when there is an embedder.
    @discardableResult
    public func indexDeviceDocument(
        documentID: String, title: String?, content: String
    ) async throws -> DeviceIndexResult {
        let title = title ?? ""
        let hash = PassageSourceHash.of(title: title, content: content)
        let fits = embedder.map { SemanticTokenBudget.fits(embedder: $0, title: title) }
        let chunks = chunker.chunk(content, fits: fits)

        let inserted: [(id: Int64, content: String)]? = try database.write { conn in
            try Self.upsertDocument(conn, documentID: documentID, sourceHash: hash, title: title)
            let serverCurrent = try Bool.fetchOne(conn, sql: """
                SELECT EXISTS (SELECT 1 FROM semantic_passages
                               WHERE document_id = ? AND origin = 'server' AND source_hash = ?)
                """, arguments: [documentID, hash]) ?? false
            if serverCurrent {
                try conn.execute(sql: """
                    DELETE FROM semantic_passages
                    WHERE document_id = ? AND (origin = 'device' OR source_hash != ?)
                    """, arguments: [documentID, hash])
                return nil
            }
            try conn.execute(sql: "DELETE FROM semantic_passages WHERE document_id = ?", arguments: [documentID])
            return try chunks.map { chunk in
                let id = try Self.insertPassage(conn, documentID: documentID, chunkIndex: chunk.index, title: title,
                                                content: chunk.content, sourceHash: hash, origin: .device)
                return (id, chunk.content)
            }
        }
        guard let inserted else { return .serverPassagesCurrent }
        if let embedder {
            for passage in inserted {
                let vector = try await embedder.embed(passage.content, task: .document(title: title))
                try database.write { conn in
                    try VectorIndex.store(conn, passageID: passage.id, stamp: embedder.stamp, vector: vector)
                }
            }
        }
        return .indexed(passages: inserted.count)
    }

    /// Stores the server's passages for `documentID`, made from the text whose
    /// hash is `sourceHash`, replacing the document's device passages and any
    /// older server passages — unless this device holds different text for
    /// the document, when they are dropped (see ``ServerApplyResult``).
    @discardableResult
    public func applyServerPassages(
        documentID: String, title: String?, sourceHash: String, passages: [ServerPassage]
    ) throws -> ServerApplyResult {
        try database.write { conn in
            let current = try String.fetchOne(
                conn, sql: "SELECT source_hash FROM semantic_documents WHERE document_id = ?", arguments: [documentID])
            if let current, current != sourceHash { return .ignoredStale(currentSourceHash: current) }
            let title = title ?? ""
            try Self.upsertDocument(conn, documentID: documentID, sourceHash: sourceHash, title: title)
            try conn.execute(sql: "DELETE FROM semantic_passages WHERE document_id = ?", arguments: [documentID])
            for passage in passages {
                let id = try Self.insertPassage(
                    conn, documentID: documentID, chunkIndex: passage.chunkIndex, title: title,
                    content: passage.content, sourceHash: sourceHash, origin: .server)
                if let vector = passage.embedding, let stamp = passage.semanticStamp {
                    try VectorIndex.store(conn, passageID: id, stamp: stamp, vector: vector)
                }
            }
            return .applied
        }
    }

    /// Forgets a document and all its passages and vectors.
    public func removeDocument(documentID: String) throws {
        try database.write { conn in
            try conn.execute(sql: "DELETE FROM semantic_documents WHERE document_id = ?", arguments: [documentID])
        }
    }

    /// Embeds up to `limit` passages that have no vector from this store's
    /// embedder — passages that arrived without one, or whose vector another
    /// model made. Returns how many were embedded; 0 without an embedder.
    @discardableResult
    public func embedPending(limit: Int = 64) async throws -> Int {
        guard let embedder, limit > 0 else { return 0 }
        let pending = try database.read { conn in
            try Row.fetchAll(conn, sql: """
                SELECT p.id, p.title, p.content FROM semantic_passages p
                LEFT JOIN semantic_vectors v ON v.passage_id = p.id AND v.semantic_stamp = ?
                WHERE v.passage_id IS NULL
                ORDER BY p.id
                LIMIT ?
                """, arguments: [embedder.stamp, limit])
        }
        for row in pending {
            let title: String = row["title"]
            let vector = try await embedder.embed(row["content"], task: .document(title: title))
            try database.write { conn in
                try VectorIndex.store(conn, passageID: row["id"], stamp: embedder.stamp, vector: vector)
            }
        }
        return pending.count
    }

    /// How many passages ``embedPending(limit:)`` has left to embed.
    public func pendingCount() throws -> Int {
        guard let embedder else { return 0 }
        return try database.read { conn in
            try Int.fetchOne(conn, sql: """
                SELECT count(*) FROM semantic_passages p
                LEFT JOIN semantic_vectors v ON v.passage_id = p.id AND v.semantic_stamp = ?
                WHERE v.passage_id IS NULL
                """, arguments: [embedder.stamp]) ?? 0
        }
    }

    // MARK: - Search

    /// At most `limit` hits for `query`, one per document. A blank query finds
    /// nothing. `fusion` applies to combined mode only, and
    /// ``CombinedFusion/reciprocalRank`` throws for a `limit` of
    /// ``SearchFusion/shortListLimit`` or less.
    public func search(
        _ query: String, mode: SearchMode, limit: Int = 10, fusion: CombinedFusion = .serverOrder
    ) async throws -> [SemanticSearchHit] {
        if mode == .combined, fusion == .reciprocalRank, limit <= SearchFusion.shortListLimit {
            throw SearchFusionError.listTooShortForRRF(limit: limit)
        }
        guard limit > 0, !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        switch mode {
        case .keyword:
            return try keywordSearch(query, limit: limit)
        case .semantic:
            return try await semanticSearch(query, limit: limit)
        case .combined:
            let keyword = try keywordSearch(query, limit: limit)
            guard embedder != nil else { return keyword }
            let semantic = try await semanticSearch(query, limit: limit)
            switch fusion {
            case .serverOrder:
                return SearchFusion.mergeRanked(semantic: semantic, keyword: keyword, limit: limit) { $0.documentID }
            case .reciprocalRank:
                return try SearchFusion.reciprocalRankFusion([semantic, keyword], limit: limit) { $0.documentID }
            }
        }
    }

    private func keywordSearch(_ query: String, limit: Int) throws -> [SemanticSearchHit] {
        try database.read { conn in try KeywordIndex.search(conn, query: query, limit: limit) }
    }

    private func semanticSearch(_ query: String, limit: Int) async throws -> [SemanticSearchHit] {
        guard let embedder else { throw SemanticSearchStoreError.noEmbedder }
        let vector = try await embedder.embed(query, task: .query)
        return try database.read { conn in
            try VectorIndex.search(conn, query: vector, stamp: embedder.stamp, limit: limit)
        }
    }

    // MARK: - Rows

    private static func upsertDocument(_ conn: Database, documentID: String, sourceHash: String, title: String) throws {
        try conn.execute(sql: """
            INSERT INTO semantic_documents (document_id, source_hash, title) VALUES (?, ?, ?)
            ON CONFLICT(document_id) DO UPDATE SET source_hash = excluded.source_hash, title = excluded.title
            """, arguments: [documentID, sourceHash, title])
    }

    private static func insertPassage(
        _ conn: Database, documentID: String, chunkIndex: Int, title: String, content: String,
        sourceHash: String, origin: PassageOrigin
    ) throws -> Int64 {
        try conn.execute(sql: """
            INSERT INTO semantic_passages (document_id, chunk_index, title, content, source_hash, origin)
            VALUES (?, ?, ?, ?, ?, ?)
            """, arguments: [documentID, chunkIndex, title, content, sourceHash, origin.rawValue])
        return conn.lastInsertedRowID
    }
}
