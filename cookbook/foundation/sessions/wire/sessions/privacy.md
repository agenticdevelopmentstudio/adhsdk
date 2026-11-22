
- **Data collected**: None. The namespace holds no data, `VisibleText` keeps nothing it filters, and `StenographerBilling` is a key prefix, not a value.
- **Storage**: None here. `VisibleText` is one of the defences in front of storage and logs: `AccountRouterLog.scrub` deletes invisible scalars first so none can split a secret token or hide its prefix from the redaction that follows, and `insertRouterExchange` stores only the visible characters of the model, provider and stop-reason columns. Redaction itself is `AccountRouterLog`'s, not this ingredient's.
- **Transmission**: None; no file here sends data anywhere.
- **Retention**: Not applicable; nothing is retained. Member types that carry identifying or secret data (for example `Sessions.ClaudeCredentialDTO`) state their privacy terms in their own recipes.

