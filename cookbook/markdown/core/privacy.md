
- **Data collected**: markdown-core touches only the document `content` string a caller supplies (plus the `id`, `ownerKind`, `ownerID`, and timestamps `MarkdownDocument` is constructed with); it derives no new personal data of its own beyond hashing that content (`contentHash`).
- **Storage**: None of these sources persist anything. `MarkdownDocument` is an in-memory value type, and the web hook/pipeline hold no document cache beyond the module-scope shiki highlighter/processor singletons, which store compiled highlighting grammars, not document content.
- **Transmission**: `defaultMarkdownFetcher` sends only the caller-supplied, URL-encoded `id` to `/api/content/markdown/{id}` over `credentials: 'same-origin'`; no other `MarkdownDocument` field is transmitted by this ingredient.
- **Retention**: Not applicable — markdown-core enforces no retention policy of its own. `MarkdownDocument.deletedAt`/`isDeleted` are server-owned soft-delete fields this ingredient reads and writes but does not act on.

