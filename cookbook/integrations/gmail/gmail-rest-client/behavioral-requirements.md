
Contract: `GmailRESTClient` conforms to `GmailAPI` (itself `Sendable`) and every operation is `async throws`. The initializer is `init(session: URLSession = .shared, sleep: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) }, pacer: GmailQuotaPacer = .shared, accessToken: @escaping @Sendable () async throws -> String)`. The module-visible helpers `isRateLimited(_:_:)`, `backoff(retry:retryAfter:)` and `maxRetries` are specified here because tests call them.

### Request construction

- **base-url**: Every request MUST be sent to `https://gmail.googleapis.com/gmail/v1/users/me/` followed by the operation path, and MUST NOT target any other host.
- **bearer-header**: Every request MUST carry the header `Authorization: Bearer <token>`, where `<token>` is the string returned by the `accessToken` closure.
- **token-once-per-call**: The `accessToken` closure MUST be awaited once when an operation builds its request, and the retries of that request MUST reuse the same `Authorization` header without calling the closure again.
- **token-failure-propagates**: An error thrown by the `accessToken` closure MUST propagate unchanged to the caller, and no HTTP request MUST be sent.
- **invalid-url-error**: When the base URL plus path cannot form a valid URL, the operation MUST throw `IntegrationError.gmail(status: 0, message: "Invalid URL for <path>")` and MUST NOT send a request.
- **query-only-when-present**: The query string MUST be set only when the operation supplies at least one query item; `profile` and `labels` send none.
- **path-id-unvalidated**: NEEDS REVIEW: Not implemented in source. `thread(id:)` and `message(id:)` interpolate `id` into the URL path with no validation or percent-encoding, so an id containing `/`, `?` or `#` changes the route or query instead of failing; the `invalid-url-error` guard catches only strings URL parsing rejects. Evidence that would settle it: a statement that ids always come from Gmail responses (opaque hexadecimal) and so are trusted, or a test of an id such as `a/b`.

### Operations

- **profile-call**: `profile()` MUST send `GET profile` with no query and a pacer cost of 1, and MUST return the decoded `GmailProfile` (`emailAddress`, `historyId`).
- **list-parameters**: `listMessageIds(query:includeSpamTrash:pageToken:)` MUST send `GET messages` with `q` set to the query and `maxResults` fixed at `500`, and a pacer cost of 5.
- **list-spam-trash-flag**: `listMessageIds` MUST add `includeSpamTrash=true` only when `includeSpamTrash` is true, and MUST omit the parameter when it is false.
- **list-page-token**: `listMessageIds` MUST add `pageToken` only when `pageToken` is non-nil.
- **list-result**: `listMessageIds` MUST return the ids from the response `messages` array with duplicates removed (the first occurrence of each id kept, order preserved), an empty list when `messages` is absent, and the response `nextPageToken` unchanged.
- **search-parameters**: `searchMessageIds(query:labelIds:maxResults:pageToken:)` MUST send `GET messages` with `q` set to the query, `maxResults` set to the caller's integer in decimal, a pacer cost of 5, and MUST NOT send `includeSpamTrash`.
- **search-label-ids**: `searchMessageIds` MUST send one `labelIds` query item per element of `labelIds`, in array order, and none when the array is empty.
- **search-page-token**: `searchMessageIds` MUST add `pageToken` only when `pageToken` is non-nil.
- **search-result**: `searchMessageIds` MUST return the same page shape as `list-result`: deduplicated ids in first-seen order, an empty list when `messages` is absent, and `nextPageToken` unchanged.
- **thread-call**: `thread(id:)` MUST send `GET threads/<id>` with `format=full` and a pacer cost of 10, and MUST return the decoded `GmailThreadDTO`.
- **message-call**: `message(id:)` MUST send `GET messages/<id>` with `format=full` and a pacer cost of 5, and MUST return the decoded `GmailMessageDTO`.
- **labels-call**: `labels()` MUST send `GET labels` with a pacer cost of 1 and MUST return the response `labels` array, or an empty list when `labels` is absent.
- **history-request**: `history(startHistoryId:pageToken:)` MUST send `GET history` with `startHistoryId` and four `historyTypes` items in the order `messageAdded`, `messageDeleted`, `labelAdded`, `labelRemoved`, with a pacer cost of 2, and MUST add `pageToken` only when it is non-nil.
- **history-changed-ids**: `GmailHistoryPage.changedIds` MUST list the message ids from each history entry's `messagesAdded`, then `labelsAdded`, then `labelsRemoved` (entries in response order), with duplicates removed and with any id that also appears in `deletedIds` removed.
- **history-deleted-ids**: `GmailHistoryPage.deletedIds` MUST list the message ids from every entry's `messagesDeleted`, with duplicates removed in first-seen order.
- **history-passthrough**: `GmailHistoryPage.historyId` and `nextPageToken` MUST equal the response `historyId` and `nextPageToken`, and an absent `history` array MUST yield empty `changedIds` and `deletedIds`.
- **history-cursor-expired**: When the `history` call fails with `IntegrationError.gmail(status: 404, ...)`, the client MUST throw `GmailCursorExpired` instead, and MUST NOT retry the 404.
- **batch-modify-bounds**: `batchModify(ids:add:remove:)` MUST throw `IntegrationError.gmail(status: 0, message: "batchModify takes 1–1000 ids, got <count>")` when `ids.count` is outside 1 through 1000, and MUST NOT send a request or reserve quota in that case.
- **batch-modify-limit**: The public constant `GmailRESTClient.batchModifyLimit` MUST equal `1000`, Gmail's own limit on ids per `messages/batchModify` call.
- **batch-modify-request**: `batchModify` MUST send `POST messages/batchModify` with `Content-Type: application/json`, a pacer cost of 50, and a JSON body of `ids`, `addLabelIds` and `removeLabelIds` taken from the arguments.
- **batch-modify-result**: `batchModify` MUST return no value and MUST ignore the response body of a 2xx reply.
- **caller-chunks**: `batchModify` MUST NOT split a list itself; a caller with more than 1000 ids sends chunks (the source comment calls an empty or oversized list "a caller bug, not a Gmail call").

### Pacing

- **reserve-before-each-attempt**: Every attempt, including each retry, MUST call `pacer.reserve(cost)` before sending, and MUST sleep for the returned duration through the injected `sleep` when that duration is greater than zero.
- **quota-costs**: The reserved cost MUST be 1 for `profile` and `labels`, 2 for `history`, 5 for `listMessageIds`, `searchMessageIds` and `message`, 10 for `thread`, and 50 for `batchModify`, from Google's published quota table.
- **pacer-injectable**: The `sleep` closure and the `pacer` MUST be constructor parameters, defaulting to `Task.sleep(for:)` and `GmailQuotaPacer.shared`, so a test records delays instead of sleeping.

### Retry and failure

- **success-range**: A response with status 200 through 299 MUST return its body to the operation without further checks.
- **retry-status**: A response with status 429, or any status 500 through 599, MUST be retried while retries remain.
- **retry-rate-limit-403**: A 403 response for which `isRateLimited` is true MUST be retried while retries remain.
- **no-retry-other-403**: A 403 response for which `isRateLimited` is false MUST be thrown immediately as `IntegrationError.gmail` and MUST NOT be retried.
- **no-retry-other-status**: Any other non-2xx status (for example 400, 401, 404) MUST be thrown immediately and MUST NOT be retried.
- **retry-transient-network**: A `URLError` whose code is `timedOut`, `networkConnectionLost`, `notConnectedToInternet` or `cannotConnectToHost` MUST be retried while retries remain.
- **no-retry-other-network**: Any other error from the session, such as another `URLError` code, MUST propagate unchanged on the first occurrence and MUST NOT be retried.
- **retry-budget**: One shared counter MUST limit retries to `maxRetries = 6` per call, counting network errors and retryable statuses together, so a call makes at most 7 attempts.
- **retries-exhausted**: When the retry budget is spent, the client MUST throw the last failure: an `IntegrationError.gmail` for a status, or the `URLError` for a transient network error.
- **backoff-schedule**: Without a `Retry-After` value, the wait before retry number `n` (0-based) MUST be 1 second doubled `n` times, capped at 32 seconds, giving 1, 2, 4, 8, 16, 32 and 32 seconds for later retries.
- **retry-after-honoured**: When a retried HTTP response carries a `Retry-After` header that parses as an integer after trimming spaces, the wait MUST be that many seconds instead of the exponential value.
- **retry-after-capped**: A `Retry-After` wait MUST be capped at 32 seconds, and a negative value MUST be treated as 0 seconds.
- **retry-after-integer-only**: A `Retry-After` header that is not an integer (such as an HTTP date) MUST be ignored and the exponential backoff used.
- **network-retry-no-retry-after**: A retry after a network error MUST use the exponential backoff, because no response exists to carry `Retry-After`.
- **rate-limit-detection**: `isRateLimited(status, data)` MUST return true only when the status is 403, the body decodes as a Google error envelope, and either `error.status` is `RESOURCE_EXHAUSTED` or any `reason` in `error.errors` or `error.details` is `rateLimitExceeded`, `userRateLimitExceeded` or `RATE_LIMIT_EXCEEDED`.
- **rate-limit-body-undecodable**: `isRateLimited` MUST return false for a 403 whose body is not decodable as that envelope, and for every status other than 403.
- **error-mapping**: A thrown HTTP failure MUST be `IntegrationError.gmail(status: <code>, message: <text>)`, where the text is `error.message` from the JSON body, or `HTTPURLResponse.localizedString(forStatusCode:)` when the body has no readable `error.message`.
- **non-http-response**: A response that is not an `HTTPURLResponse` MUST be treated as status 0, which is not retried, and MUST throw `IntegrationError.gmail(status: 0, ...)`.
- **decode-failure**: A 2xx body that does not decode into the operation's wire type MUST propagate the `DecodingError` unchanged, and MUST NOT be retried.

### Concurrency and cancellation

- **stateless-concurrent**: The client MUST hold no mutable state, so concurrent operation calls are independent; each call has its own retry counter and shares only the injected `pacer`, an `actor` that serialises reservations.
- **cancellation-propagates**: An error thrown by the `sleep` closure, such as the `CancellationError` from `Task.sleep` when the task is cancelled, MUST propagate out of the call and end the retry loop.

