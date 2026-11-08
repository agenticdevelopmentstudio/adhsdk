import Foundation
import GRDB

/// Keyword search over `semantic_passages_fts`.
enum KeywordIndex {

    /// The FTS5 query for what a person typed: each whitespace-separated word
    /// as a quoted string (an embedded `"` doubled), joined by spaces, which
    /// FTS5 reads as AND — the same every-word-must-appear reading as the
    /// backend's `plainto_tsquery`. Quoting means no FTS5 operator
    /// (`OR`, `NEAR`, `*`, `^`, `:`) is ever taken from the text. A word with
    /// no letter or digit tokenizes to nothing, so it is dropped. `nil` when
    /// no word is left.
    static func matchExpression(for query: String) -> String? {
        let terms = query
            .split(whereSeparator: { $0.isWhitespace })
            .filter { $0.contains(where: { $0.isLetter || $0.isNumber }) }
            .map { "\"" + $0.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }
        return terms.isEmpty ? nil : terms.joined(separator: " ")
    }

    /// The best-matching passage of each document, best document first, at
    /// most `limit`. bm25 is lower-is-better; equal ranks fall back to
    /// document id and chunk index so the order is deterministic.
    static func search(_ conn: Database, query: String, limit: Int) throws -> [SemanticSearchHit] {
        guard limit > 0, let match = matchExpression(for: query) else { return [] }
        let rows = try Row.fetchAll(conn, sql: """
            SELECT id, document_id, chunk_index, title, content, origin FROM (
                SELECT id, document_id, chunk_index, title, content, origin, rank,
                       ROW_NUMBER() OVER (PARTITION BY document_id ORDER BY rank, chunk_index) AS document_rank
                FROM (
                    SELECT p.id, p.document_id, p.chunk_index, p.title, p.content, p.origin,
                           bm25(semantic_passages_fts) AS rank
                    FROM semantic_passages_fts
                    JOIN semantic_passages p ON p.id = semantic_passages_fts.rowid
                    WHERE semantic_passages_fts MATCH ?
                )
            )
            WHERE document_rank = 1
            ORDER BY rank, document_id, chunk_index
            LIMIT ?
            """, arguments: [match, limit])
        return rows.map { SemanticSearchHit(row: $0, similarity: nil) }
    }
}
