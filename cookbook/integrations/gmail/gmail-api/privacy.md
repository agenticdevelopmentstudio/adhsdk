
- **Data collected**: The types carry the user's Gmail address, message ids, headers, snippets, bodies, attachment ids and label names, read from Gmail on behalf of the signed-in user.
- **Storage**: None in this file; the DTOs are transient decoded values. What the sync engine mirrors is decided by `MailClassifier`, outside this file.
- **Transmission**: The protocol's implementation sends requests to Gmail; `batchModify` writes label changes back to Gmail. This file itself does no I/O.
- **Retention**: Not applicable in this file; retention belongs to the store that receives the data.

