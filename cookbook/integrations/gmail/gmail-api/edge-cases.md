
- **empty-thread**: A thread with no `messages` key MUST decode to an empty `messages` array, not fail.
- **empty-listing**: A listing with no messages MUST yield a `GmailIdPage` with empty `ids`; `GmailRESTClient` tolerates a missing `messages` key and de-duplicates ids (test `listMessageIdsDedupesAndToleratesEmpty`).
- **expired-cursor**: A 404 on `history` MUST throw `GmailCursorExpired` and not a generic error, so the caller can fall back to a full sync.
- **other-404**: A 404 on any other operation is not translated by this contract; it surfaces as the implementation's error.
- **window-days-boundary**: `fullSync` applies no clamping; `MailSyncSettings` documents `windowDaysRange` as 1 through 3650 and `pollIntervalRange` as 1 through 1440, and enforcement belongs to that type. A `windowDays` of 0 yields an `after:` equal to `now`.
- **sub-second-now**: `fullSync` truncates `now` to whole seconds through `Int`.
- **archived-with-spam**: With `includeArchived` true, `includeSpam` and `includeTrash` add no query terms but still set `includeSpamTrash`, so the listing call includes spam and trash.
- **batch-oversize**: More than 1000 ids MUST be rejected before any request.
- **malformed-wire**: Missing required fields (`id`, `threadId`, `name`, `type`, `emailAddress`, `historyId`) cause decoding to throw; the contract does not recover.
- **concurrent-calls**: The protocol is `Sendable`, so callers MAY invoke operations concurrently; it states no ordering rule, and a fake or client decides its own serialization. `GmailRESTClient` paces calls against a quota (test `eachCallWaitsForTheQuotaItCosts`).
- **offline**: A network failure surfaces as a thrown error from the implementation; the contract defines no offline mode. `GmailRESTClient` retries transient network errors and fails fast on non-transient ones (test `nonTransientNetworkErrorsAreNotRetried`).
- **cancellation**: The protocol declares no cancellation behavior; callers rely on Swift task cancellation in the implementation.

