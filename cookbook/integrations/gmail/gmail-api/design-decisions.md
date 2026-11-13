
**Decision**: Keep the protocol to the eight operations the sync engine uses.
**Rationale**: The doc comment says it is "small so tests can fake it"; a narrow surface keeps fakes cheap and the sync engine independent of HTTP.
**Approved**: pending

**Decision**: Surface only one typed error, `GmailCursorExpired`, for HTTP 404 on `history`.
**Rationale**: An expired history cursor is the one failure the caller must act on differently (run a full sync); other failures are the implementation's own errors.
**Approved**: pending

**Decision**: Decode a thread with a missing `messages` key as an empty thread.
**Rationale**: Gmail omits `messages` for a thread with none to show; failing there would break a sync on an ordinary response.
**Approved**: pending

**Decision**: Keep `internalDate` as a string and body `data` as base64url text in the DTOs.
**Rationale**: The DTOs mirror the wire shape; conversion belongs to the parser that consumes them, and the comments in source record the formats.
**Approved**: pending

**Decision**: Let the full-sync query only narrow the fetch.
**Rationale**: The type's comment makes `MailClassifier` the authority on what is mirrored, so the query is a bandwidth optimization and not a policy.
**Approved**: pending

**Decision**: Always set `includeSpamTrash` from `includeSpam || includeTrash`, including when `includeArchived` drops the class terms.
**Rationale**: Gmail's list call excludes Spam and Trash unless asked, so archived mode still needs the flag to return them when the user opted in.
**Approved**: pending

