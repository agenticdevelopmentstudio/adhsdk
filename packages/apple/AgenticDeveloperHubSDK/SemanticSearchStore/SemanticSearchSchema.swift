import Foundation
import GRDB

/// The tables semantic search keeps in an app's SQLite database.
///
/// - `semantic_documents` — one row per indexed document: the source hash of
///   the text the passages must match, and its title.
/// - `semantic_passages` — the passages. `origin` is `device` for a passage
///   this device made (temporary, never pushed) and `server` for one that
///   synced down. `id` is an `INTEGER PRIMARY KEY`, so the FTS5 index's
///   rowids stay stable across `VACUUM`.
/// - `semantic_vectors` — at most one vector per passage, with the stamp of
///   the model that made it. The vector is 256 little-endian half floats
///   (``HalfVectorCodec``), the backend's `halfvec(256)` layout. A vector
///   whose stamp differs from the embedder's is never compared; it is
///   re-embedded as pending.
/// - `semantic_passages_fts` — an external-content FTS5 index over each
///   passage's content and title, ranked by bm25, kept in step by triggers.
///   `unicode61` with diacritics removed splits on Unicode word boundaries
///   and folds case; it does not segment Chinese or Japanese text, which the
///   semantic side still covers.
///
/// Every statement is `IF NOT EXISTS`, so ``create(in:)`` is safe on every
/// open.
public enum SemanticSearchSchema {

    public static let statements: [String] = [
        """
        CREATE TABLE IF NOT EXISTS semantic_documents (
            document_id TEXT PRIMARY KEY NOT NULL,
            source_hash TEXT NOT NULL,
            title TEXT NOT NULL DEFAULT ''
        )
        """,
        """
        CREATE TABLE IF NOT EXISTS semantic_passages (
            id INTEGER PRIMARY KEY,
            document_id TEXT NOT NULL
                REFERENCES semantic_documents(document_id) ON DELETE CASCADE,
            chunk_index INTEGER NOT NULL,
            title TEXT NOT NULL DEFAULT '',
            content TEXT NOT NULL,
            source_hash TEXT NOT NULL,
            origin TEXT NOT NULL CHECK (origin IN ('device', 'server')),
            UNIQUE (document_id, origin, chunk_index)
        )
        """,
        "CREATE INDEX IF NOT EXISTS semantic_passages_document ON semantic_passages(document_id)",
        """
        CREATE TABLE IF NOT EXISTS semantic_vectors (
            passage_id INTEGER PRIMARY KEY NOT NULL
                REFERENCES semantic_passages(id) ON DELETE CASCADE,
            semantic_stamp TEXT NOT NULL,
            embedding BLOB NOT NULL
        )
        """,
        "CREATE INDEX IF NOT EXISTS semantic_vectors_stamp ON semantic_vectors(semantic_stamp)",
        """
        CREATE VIRTUAL TABLE IF NOT EXISTS semantic_passages_fts USING fts5(
            content, title,
            content='semantic_passages', content_rowid='id',
            tokenize='unicode61 remove_diacritics 2'
        )
        """,
        """
        CREATE TRIGGER IF NOT EXISTS semantic_passages_fts_insert AFTER INSERT ON semantic_passages BEGIN
            INSERT INTO semantic_passages_fts(rowid, content, title) VALUES (new.id, new.content, new.title);
        END
        """,
        """
        CREATE TRIGGER IF NOT EXISTS semantic_passages_fts_delete AFTER DELETE ON semantic_passages BEGIN
            INSERT INTO semantic_passages_fts(semantic_passages_fts, rowid, content, title)
                VALUES ('delete', old.id, old.content, old.title);
        END
        """,
        """
        CREATE TRIGGER IF NOT EXISTS semantic_passages_fts_update AFTER UPDATE ON semantic_passages BEGIN
            INSERT INTO semantic_passages_fts(semantic_passages_fts, rowid, content, title)
                VALUES ('delete', old.id, old.content, old.title);
            INSERT INTO semantic_passages_fts(rowid, content, title) VALUES (new.id, new.content, new.title);
        END
        """
    ]

    /// Creates any table, index or trigger that is missing.
    public static func create(in conn: Database) throws {
        for statement in statements {
            try conn.execute(sql: statement)
        }
    }
}
