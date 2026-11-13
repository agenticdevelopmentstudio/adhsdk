
- **protocol-sendable**: `GmailAPI` MUST be `Sendable`, and every operation MUST be `async throws`.
- **profile-returns**: `profile()` MUST return a `GmailProfile` carrying `emailAddress` and `historyId`, both non-optional strings.
- **list-message-ids**: `listMessageIds(query:includeSpamTrash:pageToken:)` MUST return a `GmailIdPage` of message ids plus an optional `nextPageToken`.
- **list-spam-trash-flag**: `listMessageIds` MUST take `includeSpamTrash` from its caller; `GmailQuery.fullSync` supplies the value to pass.
- **search-message-ids**: `searchMessageIds(query:labelIds:maxResults:pageToken:)` MUST return one page of a Gmail search, newest first, of messages matching `query` (Gmail's search syntax) that carry every label in `labelIds`.
- **search-spam-trash**: `searchMessageIds` MUST include Spam and Trash messages only when the query asks for them, through `in:spam` or `in:trash` terms in `query`; the method has no `includeSpamTrash` parameter.
- **thread-fetch**: `thread(id:)` MUST return a `GmailThreadDTO` holding the conversation and every message in it, oldest first (`threads.get`, format full).
- **thread-messages-optional**: `GmailThreadDTO` MUST decode to an empty `messages` array when the wire object has no `messages` key, because "Gmail leaves `messages` out of a thread with none it will show."
- **thread-id-required**: `GmailThreadDTO` decoding MUST fail when `id` is absent.
- **message-fetch**: `message(id:)` MUST return a `GmailMessageDTO`.
- **message-shape**: `GmailMessageDTO` MUST require `id` and `threadId` and MUST treat `labelIds`, `snippet`, `historyId`, `internalDate` and `payload` as optional.
- **internal-date-format**: `GmailMessageDTO.internalDate` MUST be carried as a string of epoch milliseconds, undecoded into a date.
- **part-tree**: `GmailPart` MUST be a recursive tree: every field (`partId`, `mimeType`, `filename`, `headers`, `body`, `parts`) is optional and `parts` holds child `GmailPart` values.
- **body-encoding**: `GmailBody.data` MUST carry the body as base64url text, left undecoded; `attachmentId` and `size` MUST be optional.
- **header-shape**: `GmailHeader` MUST carry a required `name` and `value`.
- **history-page**: `history(startHistoryId:pageToken:)` MUST return a `GmailHistoryPage` with `changedIds`, `deletedIds`, the `historyId` and an optional `nextPageToken`.
- **cursor-expired**: `history` MUST throw `GmailCursorExpired` when Gmail answers HTTP 404, meaning the cursor "is older than Gmail keeps"; the caller then needs a full sync.
- **cursor-expired-shape**: `GmailCursorExpired` MUST be an `Error`, `Equatable` and `Sendable` with a no-argument initializer and no payload.
- **labels-list**: `labels()` MUST return the account's labels as `[GmailLabelDTO]`.
- **label-shape**: `GmailLabelDTO` MUST require `id`, `name` and `type` and MUST treat `messagesTotal`, `messagesUnread` and `color` (a `LabelColor` from the integration model) as optional.
- **batch-modify**: `batchModify(ids:add:remove:)` MUST apply the `add` and `remove` label ids to every id in `ids` and return nothing on success.
- **batch-modify-limits**: A conforming REST client MUST reject an empty `ids` list and a list longer than `GmailRESTClient.batchModifyLimit` (1000) with an `IntegrationError`, without calling Gmail. The protocol does not state this limit; `GmailRESTClient` enforces it and its tests assert it.
- **full-sync-after**: `GmailQuery.fullSync(settings:now:)` MUST start the query with `after:` followed by the whole-second epoch of `now` minus `settings.windowDays` days (86,400 seconds each).
- **full-sync-class-filter**: When `settings.includeArchived` is false, `fullSync` MUST append the space-joined terms `in:inbox in:sent in:drafts is:starred has:userlabels` inside braces, which Gmail reads as OR.
- **full-sync-spam-trash-terms**: When `includeArchived` is false, `fullSync` MUST add `in:spam` inside the braces, after `has:userlabels`, when `includeSpam` is true and `in:trash` after that when `includeTrash` is true.
- **full-sync-archived**: When `settings.includeArchived` is true, `fullSync` MUST return only the `after:` term, with no class filter and no `in:spam` or `in:trash` terms.
- **full-sync-include-flag**: `fullSync` MUST return `includeSpamTrash` equal to `settings.includeSpam || settings.includeTrash`, whether or not `includeArchived` is set.
- **query-narrows-only**: `GmailQuery` output MUST be treated as a fetch narrowing only; `MailClassifier` stays the authority on what is mirrored (the type's own comment).
- **no-error-translation-here**: The protocol MUST NOT define errors other than `GmailCursorExpired`; other failures surface as the throwing implementation's own errors (for `GmailRESTClient`, `IntegrationError.gmail(status:message:)`).

### Security

- **token-not-in-contract**: The `GmailAPI` protocol and DTOs MUST NOT carry an access token; authentication is the implementation's concern. `GmailRESTClient` takes an `accessToken` closure (`@Sendable () async throws -> String`) at construction, calls it for each request, and sends the result as a bearer token. Token lifetime, storage and refresh are owned by the code that supplies the `accessToken` and are outside this file.
- **mail-content-sensitive**: Message ids, headers, snippets, bodies and label names are personal mail content; they MUST NOT be altered or filtered by the contract types, which only carry them.

### Networking and Failure

- **failure-surfaces**: Each protocol operation MUST surface a failed call by throwing; no operation returns an error value. Retry, backoff, rate-limit pacing and timeouts belong to the implementation: `GmailRESTClient` retries 429, rate-limit 403, 5xx and transient network errors up to six times with exponential backoff capped at 32 seconds, honoring `Retry-After`, and its tests assert this. A fake used in tests defines its own behavior.

