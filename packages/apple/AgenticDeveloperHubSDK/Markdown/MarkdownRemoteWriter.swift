import Foundation
import AgenticDeveloperHubSDKSync

/// One queued call against adh's markdown documents ("papers").
///
/// The intents map one-for-one onto adh's `/v1/papers` gateway routes, which
/// front `routes/markdownDocuments.ts`. The `/v1` gateway is the one that
/// honours `Idempotency-Key`, so a writer sends there, keyed by the op's
/// `opID`:
///
/// | intent | request |
/// |---|---|
/// | `create` | `POST /v1/papers` with `{ content, note?, doc? }` |
/// | `update` | `POST /v1/papers/:id` with `{ content }` |
/// | `delete` | `DELETE /v1/papers/:id` |
/// | `publish` | `POST /v1/papers/:id/publish` with `{ route }` |
/// | `unpublish` | `POST /v1/papers/:id/unpublish` |
/// | `finalize` | `POST /v1/papers/:id/finalize` |
/// | `definalize` | `POST /v1/papers/:id/definalize` |
///
/// adh keeps an Idempotency-Key for 24 hours and refuses a reuse whose body
/// differs, which is why `MarkdownStore` freezes an op's body once it has been
/// handed to a writer (see `MarkdownStore.drainRemoteQueue`).
///
/// `category` and `tags` are keys on adh's create and update schemas but are
/// deliberately absent from these payloads: a document's classification lives
/// in the `content.category_items`/`content.keyword_items` link rows, which are
/// *not* pull-only and therefore already push themselves through the generic
/// sync outbox (`MarkdownTaxonomy` stages a `LocalMutation` for each). Putting
/// them on the document body as well would make two independent writers for one
/// piece of state. `title` is absent because adh derives it from the content —
/// it is not a key on either schema, and a caller that sends one has it
/// stripped.
///
/// Reads are absent on purpose: the sync pull supplies everything except
/// version history, which has no local table at all (`content.markdown_versions`
/// carries no sync columns, so it is not in `ADHSyncCatalog`).
public enum MarkdownRemoteIntent: String, Sendable, CaseIterable {
    case create, update, delete, publish, unpublish, finalize, definalize
}

public struct MarkdownRemoteOp: Equatable, Sendable {
    public let opID: String
    /// The document's identity *locally* — the id every local table, and every
    /// caller holding a `MarkdownDocument`, addresses it by.
    public let documentID: String
    /// The id adh knows the same document by, or `nil` when adh has not been
    /// told about it yet.
    ///
    /// These are two different identifiers, and the store keeps both rather
    /// than replacing one with the other: `POST /v1/papers` takes no
    /// `id`, so the server mints its own and returns it at 201, while the
    /// local id is already load-bearing (`MarkdownNoteStorage` derives it from
    /// `Note.id`, and the taxonomy link rows cite it as `target_id`).
    /// Rewriting the local id to match the server's would silently invalidate
    /// all of that, so `_markdown_remote_id` records the pairing instead and
    /// this field carries it out to the writer, which addresses `/v1/papers/:id`
    /// with it.
    public let remoteID: String?
    public let intent: MarkdownRemoteIntent
    public let payload: [String: JSONValue]
    public let createdAt: Date

    public init(
        opID: String, documentID: String, remoteID: String? = nil,
        intent: MarkdownRemoteIntent, payload: [String: JSONValue], createdAt: Date
    ) {
        self.opID = opID
        self.documentID = documentID
        self.remoteID = remoteID
        self.intent = intent
        self.payload = payload
        self.createdAt = createdAt
    }
}

/// Drains `_markdown_outbox` against adh.
///
/// adhd's `HubMarkdownRemoteWriter` implements it. The queue is durable rather
/// than best-effort so that edits made while no writer can reach adh (signed
/// out, offline) are still there when one can.
public protocol MarkdownRemoteWriter: Sendable {
    /// Throws to leave the op queued. Returning normally means adh accepted it.
    ///
    /// A throw does not mean adh never saw the op: the op stays claimed and is
    /// resent unchanged, under the same `opID`, on the next drain. A writer
    /// therefore sends `opID` as the Idempotency-Key on every non-update call.
    ///
    /// The return value is the id adh assigned, and only a `.create` can have
    /// one — every other intent addresses a document adh already has, at
    /// `remoteOp.remoteID`. A writer that returns it lets
    /// `MarkdownStore.drainRemoteQueue` record the local↔remote pairing before
    /// any later op for the same document is sent; returning `nil` from a
    /// `.create` is legal and means "no id to record" (an echo or test writer),
    /// leaving every subsequent op for that document without a remote id.
    @discardableResult
    func send(_ remoteOp: MarkdownRemoteOp) async throws -> String?
}
