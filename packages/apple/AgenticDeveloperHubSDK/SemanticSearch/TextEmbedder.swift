import Foundation

/// What a vector is for. The model was trained with a different prefix for
/// each, so a query and a passage with the same words embed differently, and
/// only a query vector compared with document vectors ranks anything.
public enum EmbeddingTask: Sendable, Hashable {
    /// A search query.
    case query
    /// A stored passage, with its document's title. `nil` or an empty title
    /// means the document has none — the backend passes `title || null`, so an
    /// empty string and no title embed the same way.
    case document(title: String?)

    /// The title this task embeds with, `nil` when it has none.
    public var documentTitle: String? {
        guard case .document(let title) = self, let title, !title.isEmpty else { return nil }
        return title
    }
}

/// Turns text into a semantic search vector. Callers depend on this, never on
/// a model, so a test can supply a fake and a better model can be dropped in
/// later as a new bundle.
///
/// Every implementation follows `docs/specs/ingredients/semantic-search.md`:
/// the bundle's task prefixes, a cap of ``TokenLimit/maxEmbedTokens`` tokens,
/// the vector cut to ``dimensions`` and renormalised to unit length.
public protocol TextEmbedder: Sendable {
    /// Names the exact model that makes this embedder's vectors (see
    /// ``SemanticStamp``). Two vectors are comparable only when their stamps
    /// are equal.
    var stamp: String { get }

    /// The length of every vector this embedder returns.
    var dimensions: Int { get }

    /// How many tokens the model would read for `text` under `task`, the
    /// prefix, `<bos>` and `<eos>` included, before any cap. The chunker uses
    /// it to keep a passage within ``TokenLimit/maxEmbedTokens``.
    func tokenCount(_ text: String, task: EmbeddingTask) throws -> Int

    /// A unit-length vector of ``dimensions`` floats for `text` under `task`.
    func embed(_ text: String, task: EmbeddingTask) async throws -> [Float]
}

/// The bundle's task prefixes: the text the model expects in front of a query
/// or a passage.
public struct EmbeddingPrefixes: Sendable, Hashable, Decodable {
    /// Put in front of a query.
    public let query: String
    /// Put in front of a titled passage; its first `{title}` is replaced by
    /// the title.
    public let document: String
    /// Put in front of a passage whose document has no title.
    public let documentUntitled: String

    public init(query: String, document: String, documentUntitled: String) {
        self.query = query
        self.document = document
        self.documentUntitled = documentUntitled
    }

    enum CodingKeys: String, CodingKey {
        case query, document
        case documentUntitled = "document_untitled"
    }

    /// `text` with the prefix for `task` in front. Only the FIRST `{title}`
    /// is replaced, and the title goes in literally, as the backend's
    /// `String.replace('{title}', () => title)` does.
    public func apply(_ text: String, task: EmbeddingTask) -> String {
        switch task {
        case .query:
            return query + text
        case .document:
            guard let title = task.documentTitle else { return documentUntitled + text }
            var prefix = document
            if let range = prefix.range(of: "{title}") {
                prefix.replaceSubrange(range, with: title)
            }
            return prefix + text
        }
    }
}
