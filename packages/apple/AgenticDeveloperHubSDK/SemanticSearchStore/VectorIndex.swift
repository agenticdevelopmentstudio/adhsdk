import Foundation
import GRDB
import AgenticDeveloperHubSDKSemanticSearch

/// Brute-force semantic search over `semantic_vectors`.
///
/// Every vector with the embedder's stamp is decoded into one contiguous
/// row-major matrix and scored against the query in one `vDSP_mmul`. At 256
/// half floats a vector is 512 bytes, so 10,000 passages are 5 MB to read and
/// one matrix-vector product to score — well under the cost of embedding the
/// query. An approximate index earns its complexity only far past that.
enum VectorIndex {

    /// Stores `vector` for `passageID` under `stamp`, replacing any earlier
    /// vector. Skipped when the passage is gone — a passage replaced while
    /// its vector was being computed.
    static func store(_ conn: Database, passageID: Int64, stamp: String, vector: [Float]) throws {
        try conn.execute(sql: """
            INSERT OR REPLACE INTO semantic_vectors (passage_id, semantic_stamp, embedding)
            SELECT ?, ?, ? WHERE EXISTS (SELECT 1 FROM semantic_passages WHERE id = ?)
            """, arguments: [passageID, stamp, HalfVectorCodec.encode(vector), passageID])
    }

    /// The best-scoring passage of each document, best document first, at
    /// most `limit`, scored by dot product with `query` (cosine, since both
    /// sides are unit length). Equal scores keep document id then chunk
    /// index order.
    static func search(
        _ conn: Database, query: [Float], stamp: String, limit: Int, filter: SemanticSearchFilter? = nil
    ) throws -> [SemanticSearchHit] {
        guard limit > 0, !query.isEmpty else { return [] }
        let dims = query.count
        let rows = try Row.fetchAll(conn, sql: """
            SELECT v.passage_id, p.document_id, v.embedding
            FROM semantic_vectors v JOIN semantic_passages p ON p.id = v.passage_id
            WHERE v.semantic_stamp = ?\(filter.map { " AND " + $0.predicate } ?? "")
            ORDER BY p.document_id, p.chunk_index
            """, arguments: StatementArguments([stamp]) + (filter?.arguments ?? StatementArguments()))
        guard !rows.isEmpty else { return [] }

        var matrix = [Float](repeating: 0, count: rows.count * dims)
        var passageIDs: [Int64] = []
        var documentIDs: [String] = []
        passageIDs.reserveCapacity(rows.count)
        documentIDs.reserveCapacity(rows.count)
        for (index, row) in rows.enumerated() {
            let blob: Data = row["embedding"]
            guard blob.count == dims * 2 else {
                throw HalfVectorCodecError.wrongLength(bytes: blob.count, dimensions: dims)
            }
            HalfVectorCodec.decode(blob, into: &matrix, at: index * dims)
            passageIDs.append(row["passage_id"])
            documentIDs.append(row["document_id"])
        }
        let scores = VectorMath.dotProducts(query: query, matrix: matrix)

        // Rows arrive grouped by document, so one pass keeps each document's best.
        var bestScores: [Float] = []
        var bestPassages: [Int64] = []
        var lastDocument: String?
        for index in scores.indices {
            if documentIDs[index] != lastDocument {
                lastDocument = documentIDs[index]
                bestScores.append(scores[index])
                bestPassages.append(passageIDs[index])
            } else if scores[index] > bestScores[bestScores.count - 1] {
                bestScores[bestScores.count - 1] = scores[index]
                bestPassages[bestPassages.count - 1] = passageIDs[index]
            }
        }

        let chosen = VectorMath.topK(bestScores, k: limit)
        let ids = chosen.map { bestPassages[$0.index] }
        let placeholders = Array(repeating: "?", count: ids.count).joined(separator: ",")
        let hitRows = try Row.fetchAll(conn, sql: """
            SELECT id, document_id, chunk_index, title, content, origin
            FROM semantic_passages WHERE id IN (\(placeholders))
            """, arguments: StatementArguments(ids))
        var byID: [Int64: Row] = [:]
        for row in hitRows { byID[row["id"]] = row }
        return chosen.compactMap { scored in
            byID[bestPassages[scored.index]].map { SemanticSearchHit(row: $0, similarity: scored.score) }
        }
    }
}
