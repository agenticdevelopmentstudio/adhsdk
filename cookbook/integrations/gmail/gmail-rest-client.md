---
id: c448c9f4-195d-4625-a49d-22dd5468a914
title: "Gmail REST Client"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-13
modified: 2026-11-13
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Gmail API over URLSession: bearer auth, quota pacing, retry with capped backoff, error mapping and history, listing and batch-modify wire handling."
platforms:
  - swift
  - macos
  - ios
tags:
  - gmail
  - mail-sync
  - rest-client
  - retry
  - rate-limit
depends-on:
  - 18871853-95b7-492a-9f1f-417283594824
related:
  - cdadfe1d-e4a2-4e2d-96a7-a5eb615a1302
references: []
approved-by: ""
approved-date: ""
---

# Gmail REST Client

## Overview

`GmailRESTClient` is the production implementation of the `GmailAPI` protocol ([adhsdk.ingredient.integrations.gmail.gmail-api](cookbook:18871853-95b7-492a-9f1f-417283594824)). It is a `public final class` that calls the Gmail REST API at `https://gmail.googleapis.com/gmail/v1/users/me/` through an injected `URLSession`, and holds no mutable state. A caller supplies an `accessToken` closure that returns a fresh bearer token; the client never stores or refreshes a credential.

It exposes eight operations: `profile`, `listMessageIds`, `searchMessageIds`, `thread`, `message`, `history`, `labels` and `batchModify`. Around them sits shared plumbing that every operation uses: request building, quota pacing through a `GmailQuotaPacer`, a retry loop with exponential backoff, and mapping of a failed response to `IntegrationError.gmail(status:message:)`. Turning a returned message into a record is a separate component ([adhsdk.ingredient.integrations.gmail.gmail-message-parser](cookbook:cdadfe1d-e4a2-4e2d-96a7-a5eb615a1302)); deciding when to call, how to chunk and what to do with a `GmailCursorExpired` belongs to the sync engine and `MailIntegrationService`.

The runtime flow of one network call (`send`) is a loop of attempts. Each attempt reserves quota with the pacer, sleeps if told to, sends the request, and then ends in one of three ways: return the body (a 2xx status), sleep and try again (a retryable failure with retries left), or throw. Retries and pacing are explained in the requirements below.

## Behavioral Requirements

Contract: `GmailRESTClient` conforms to `GmailAPI` (itself `Sendable`) and every operation is `async throws`. The initializer is `init(session: URLSession = .shared, sleep: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) }, pacer: GmailQuotaPacer = .shared, accessToken: @escaping @Sendable () async throws -> String)`. The module-visible helpers `isRateLimited(_:_:)`, `backoff(retry:retryAfter:)` and `maxRetries` are specified here because tests call them.

### Request construction

- **base-url**: Every request MUST be sent to `https://gmail.googleapis.com/gmail/v1/users/me/` followed by the operation path, and MUST NOT target any other host.
- **bearer-header**: Every request MUST carry the header `Authorization: Bearer <token>`, where `<token>` is the string returned by the `accessToken` closure.
- **token-once-per-call**: The `accessToken` closure MUST be awaited once when an operation builds its request, and the retries of that request MUST reuse the same `Authorization` header without calling the closure again.
- **token-failure-propagates**: An error thrown by the `accessToken` closure MUST propagate unchanged to the caller, and no HTTP request MUST be sent.
- **invalid-url-error**: When the base URL plus path cannot form a valid URL, the operation MUST throw `IntegrationError.gmail(status: 0, message: "Invalid URL for <path>")` and MUST NOT send a request.
- **query-only-when-present**: The query string MUST be set only when the operation supplies at least one query item; `profile` and `labels` send none.

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
- **batch-modify-bounds**: `batchModify(ids:add:remove:)` MUST throw `IntegrationError.gmail(status: 0, message: "batchModify takes 1–1000 ids, got <count>")` when `ids.count` is outside 1 through 1000, and MUST NOT send a request or reserve quota in that case. The check runs before the request is built, so the token closure is not awaited either.
- **batch-modify-limit**: The public constant `GmailRESTClient.batchModifyLimit` MUST equal `1000`, Gmail's own limit on ids per `messages/batchModify` call.
- **batch-modify-request**: `batchModify` MUST send `POST messages/batchModify` with `Content-Type: application/json`, a pacer cost of 50, and a JSON body of `ids`, `addLabelIds` and `removeLabelIds` taken from the arguments.
- **batch-modify-result**: `batchModify` MUST return no value and MUST ignore the response body of a 2xx reply.
- **caller-chunks**: `batchModify` MUST NOT split a list itself; a caller with more than 1000 ids sends chunks (the source comment calls an empty or oversized list "a caller bug, not a Gmail call").

### Pacing

- **reserve-before-each-attempt**: Every attempt, including each retry, MUST call `pacer.reserve(cost)` before sending, and MUST sleep for the returned duration through the injected `sleep` when that duration is greater than zero.
- **quota-costs**: The reserved cost MUST be 1 for `profile` and `labels`, 2 for `history`, 5 for `listMessageIds`, `searchMessageIds` and `message`, 10 for `thread`, and 50 for `batchModify`, from Google's published quota table.
- **pacer-injectable**: The `sleep` closure and the `pacer` MUST be constructor parameters, defaulting to `Task.sleep(for:)` and `GmailQuotaPacer.shared`, so a test records delays instead of sleeping. The `pacer` is the concrete `GmailQuotaPacer` actor, not a protocol, so a test cannot count reservations directly; it observes them through the recorded sleeps of a pacer built with a low rate, zero burst and a stopped `now` clock, where each reservation adds its cost divided by the rate to the next wait.

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
- **backoff-schedule**: Without a `Retry-After` value, the wait before retry number `n` (0-based) MUST be 1 second doubled `n` times, capped at 32 seconds, giving 1, 2, 4, 8, 16 and 32 seconds for the six retries; the same formula for a larger `n` stays at 32 seconds.
- **retry-after-honoured**: When a retried HTTP response carries a `Retry-After` header that parses as an integer after trimming spaces, the wait MUST be that many seconds instead of the exponential value.
- **retry-after-capped**: A `Retry-After` wait MUST be capped at 32 seconds, and a negative value MUST be treated as 0 seconds.
- **retry-after-integer-only**: A `Retry-After` header that is not an integer (such as an HTTP date) MUST be ignored and the exponential backoff used.
- **network-retry-no-retry-after**: A retry after a network error MUST use the exponential backoff, because no response exists to carry `Retry-After`.
- **rate-limit-detection**: `isRateLimited(status, data)` MUST return true only when the status is 403, the body decodes as a Google error envelope, and either `error.status` is `RESOURCE_EXHAUSTED` or any `reason` in `error.errors` or `error.details` is `rateLimitExceeded`, `userRateLimitExceeded` or `RATE_LIMIT_EXCEEDED`.
- **rate-limit-body-undecodable**: `isRateLimited` MUST return false for a 403 whose body is not decodable as that envelope, and for every status other than 403.
- **error-mapping**: A thrown HTTP failure MUST be `IntegrationError.gmail(status: <code>, message: <text>)`, where the text is `error.message` from the JSON body, or `HTTPURLResponse.localizedString(forStatusCode:)` when the body has no readable `error.message`.
- **non-http-response**: A response that is not an `HTTPURLResponse` MUST be treated as status 0, which is not retried, and MUST throw `IntegrationError.gmail(status: 0, ...)`.
- **decode-failure**: A 2xx body that does not decode into the operation's wire type MUST propagate the `DecodingError` unchanged, and MUST NOT be retried. This is recorded as technical debt in Design Decisions: the error is not an `IntegrationError`.

### Concurrency and cancellation

- **stateless-concurrent**: The client MUST hold no mutable state, so concurrent operation calls are independent; each call has its own retry counter and shares only the injected `pacer`, an `actor` that serialises reservations.
- **cancellation-propagates**: An error thrown by the `sleep` closure, such as the `CancellationError` from `Task.sleep` when the task is cancelled, MUST propagate out of the call and end the retry loop.

## Appearance

Not applicable — this is a network client with no visual surface, not a visual component.

## States

Not applicable — this is a network client with no visual surface, not a visual component.

## Accessibility

Not applicable — this is a network client with no visual surface, not a visual component.

## Conformance Test Vectors

Vectors named for a test come from `GmailRESTClientTests`; the rest are derived from the code and have no test beside them. The tests run over a stub `URLSession` with a recording `sleep` and a pacer set so large it never waits, unless stated.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| gmail-rest-client-001 | bearer-header, base-url, profile-call | `profile()` with token `secret`, reply 200 `{"emailAddress":"me@x.com","historyId":"7"}` (test `sendsBearerToken`) | One request with `Authorization: Bearer secret`; result `emailAddress == "me@x.com"`. |
| gmail-rest-client-002 | list-parameters, list-spam-trash-flag, list-page-token, base-url | `listMessageIds(query: "after:1 in:inbox", includeSpamTrash: true, pageToken: "p9")` (test `listMessageIdsSendsItsParameters`) | Path `/gmail/v1/users/me/messages`; items `q=after:1 in:inbox`, `maxResults=500`, `includeSpamTrash=true`, `pageToken=p9`. |
| gmail-rest-client-003 | list-spam-trash-flag, list-page-token | `listMessageIds(query: "after:2", includeSpamTrash: false, pageToken: nil)` (same test) | Items include `q=after:2`; no `includeSpamTrash` item and no `pageToken` item. |
| gmail-rest-client-004 | list-result | Reply 200 `{"messages":[{"id":"x"},{"id":"y"},{"id":"x"}],"nextPageToken":"n"}` (test `listMessageIdsDedupesAndToleratesEmpty`) | `ids == ["x","y"]`, `nextPageToken == "n"`. |
| gmail-rest-client-005 | list-result | Reply 200 `{}` (same test) | `ids` is empty and `nextPageToken` is nil; no error. |
| gmail-rest-client-006 | search-parameters, search-label-ids, search-page-token, search-result | `searchMessageIds(query: "from:greenhouse", labelIds: ["INBOX","Label_1"], maxResults: 25, pageToken: "p")` (test `searchSendsTheQueryEachLabelAndThePageSize`) | Items `q=from:greenhouse`, `labelIds=INBOX`, `labelIds=Label_1` in that order, `maxResults=25`, `pageToken=p`; `ids == ["x","y"]` for reply `{"messages":[{"id":"x"},{"id":"y"}],"nextPageToken":"n"}`. |
| gmail-rest-client-007 | search-label-ids, search-parameters | `searchMessageIds(query: "q", labelIds: [], maxResults: 10, pageToken: nil)` (derived) | Items `q` and `maxResults=10` only; no `labelIds`, no `includeSpamTrash`, no `pageToken`. |
| gmail-rest-client-008 | thread-call | `thread(id: "t1")`, reply `{"id":"t1","messages":[{"id":"a","threadId":"t1"},{"id":"b","threadId":"t1"}]}` (test `threadAsksForEveryMessageInFull`) | Path `/gmail/v1/users/me/threads/t1`, item `format=full`; messages ids `["a","b"]`. |
| gmail-rest-client-009 | thread-call | `thread(id: "t1")`, reply `{"id":"t1"}` (test `aThreadWithNoMessagesDecodesEmpty`) | `messages` is empty; no error. |
| gmail-rest-client-010 | message-call, quota-costs | `message(id: "m1")` (derived) | `GET /gmail/v1/users/me/messages/m1?format=full`; one reservation of 5 units. |
| gmail-rest-client-011 | labels-call | `labels()` with reply `{}` (derived) | `GET /gmail/v1/users/me/labels` with no query; result is an empty list. |
| gmail-rest-client-012 | history-request, history-changed-ids, history-deleted-ids, history-passthrough | `history(startHistoryId: "100", pageToken: "p1")` over the `history` fixture (test `historyPageCollectsChangedAndDeleted`) | Path `/gmail/v1/users/me/history`; `startHistoryId=100`, `pageToken=p1`, `historyTypes` values `messageAdded, messageDeleted, labelAdded, labelRemoved`; `changedIds == ["a","b"]`, `deletedIds == ["c"]`, `historyId == "950"`, `nextPageToken == "p2"`. |
| gmail-rest-client-013 | history-changed-ids | Entries where id `m` is in `messagesAdded` and also in `messagesDeleted`, and id `k` appears in `labelsAdded` twice (derived) | `changedIds == ["k"]`, `deletedIds == ["m"]`. |
| gmail-rest-client-014 | history-passthrough | `history` reply `{"historyId":"9"}` (derived; also the reply used in test `eachCallWaitsForTheQuotaItCosts`) | `changedIds` and `deletedIds` are empty, `historyId == "9"`, `nextPageToken` is nil. |
| gmail-rest-client-015 | history-cursor-expired | `history(startHistoryId: "1", pageToken: nil)`, reply 404 `{"error":{"code":404,"message":"Not Found"}}` (test `historyNotFoundThrowsCursorExpired`) | Throws `GmailCursorExpired`; one request, no sleep. |
| gmail-rest-client-016 | batch-modify-request, batch-modify-result | `batchModify(ids: ["a"], add: ["STARRED"], remove: ["INBOX"])`, reply 200 empty body (test `batchModifyPostsBody`) | Method `POST`; JSON body equals `{"ids":["a"],"addLabelIds":["STARRED"],"removeLabelIds":["INBOX"]}`; returns normally. |
| gmail-rest-client-017 | batch-modify-bounds, batch-modify-limit | `batchModify` with `ids: []`, then with 1001 ids (`(0...GmailRESTClient.batchModifyLimit)`) (test `batchModifyRejectsEmptyAndOversizedListsWithoutCallingGmail`) | Both throw `IntegrationError`; the stub records zero requests. |
| gmail-rest-client-018 | batch-modify-bounds | `batchModify(ids: [], add: [], remove: [])` (derived) | Throws `IntegrationError.gmail(status: 0, message: "batchModify takes 1–1000 ids, got 0")`. |
| gmail-rest-client-019 | batch-modify-bounds | `batchModify` with exactly 1000 ids (derived) | One POST is sent; no bounds error. |
| gmail-rest-client-020 | caller-chunks | `batchModify` with 1001 ids (derived) | Throws before sending; the client does not send two requests. |
| gmail-rest-client-021 | retry-status, backoff-schedule, retry-budget | Replies 503 then 200 for `profile()` (test `serviceUnavailableIsRetriedAndSucceeds`) | Result `historyId == "7"`; 2 requests; recorded sleeps `[1 s]`. |
| gmail-rest-client-022 | retry-after-honoured, retry-status | Replies 429 with header `Retry-After: 7` then 200 (test `retryAfterIsHonoured`) | Recorded sleeps `[7 s]`. |
| gmail-rest-client-023 | retry-transient-network, backoff-schedule | Replies `timedOut`, `networkConnectionLost`, `notConnectedToInternet`, `cannotConnectToHost`, then 200 (test `transientNetworkErrorsAreRetried`) | Success; sleeps `[1 s, 2 s, 4 s, 8 s]`. |
| gmail-rest-client-024 | retries-exhausted, retry-budget, backoff-schedule | Every reply is 503 `{"error":{"code":503,"message":"Backend Error"}}` (test `retriesStopAfterSixAndTheLastErrorSurfaces`) | Throws `IntegrationError.gmail(status: 503, message: "Backend Error")`; 7 requests; sleeps `[1, 2, 4, 8, 16, 32]` seconds. |
| gmail-rest-client-025 | retry-rate-limit-403, rate-limit-detection | Reply 403 whose body has `errors[0].reason` `rateLimitExceeded` and `details[0].reason` `RATE_LIMIT_EXCEEDED`, then 200 (test `aRateLimit403IsRetried`) | 2 requests; sleeps `[1 s]`. |
| gmail-rest-client-026 | rate-limit-detection, rate-limit-body-undecodable | `isRateLimited(403, {"error":{"code":403,"message":"Slow down","status":"RESOURCE_EXHAUSTED"}})` and `isRateLimited(400, same body)` (test `aResourceExhausted403CountsAsRateLimited`) | First call true, second call false. |
| gmail-rest-client-027 | no-retry-other-403, error-mapping | Reply 403 with reason `insufficientPermissions` and `error.message` `Insufficient Permission` (test `aPermission403IsNotRetried`) | Throws `IntegrationError.gmail(status: 403, message: "Insufficient Permission")`; 1 request; no sleep. |
| gmail-rest-client-028 | error-mapping, no-retry-other-403 | Reply 403 `{"error":{"code":403,"message":"Insufficient Permission","status":"PERMISSION_DENIED"}}` (test `errorBodyMessageSurfaces`) | Throws the same error; 1 request; sleeps empty. |
| gmail-rest-client-029 | rate-limit-body-undecodable | `isRateLimited(403, Data("not json".utf8))` (derived) | Returns false. |
| gmail-rest-client-030 | no-retry-other-network | Reply `URLError.badURL` (test `nonTransientNetworkErrorsAreNotRetried`) | Throws `URLError`; sleeps empty. |
| gmail-rest-client-031 | backoff-schedule, retry-after-capped | `backoff(retry: 0, retryAfter: nil)`, `backoff(retry: 5, retryAfter: nil)`, `backoff(retry: 9, retryAfter: nil)`, `backoff(retry: 0, retryAfter: 300)` (test `backoffIsCappedAt32Seconds`) | 1 s, 32 s, 32 s, 32 s. |
| gmail-rest-client-032 | retry-after-capped | `backoff(retry: 0, retryAfter: -5)` (derived) | 0 s. |
| gmail-rest-client-033 | retry-after-integer-only | Reply 503 with `Retry-After: Wed, 21 Oct 2026 07:28:00 GMT`, then 200 (derived) | Sleeps `[1 s]`; the date is ignored. |
| gmail-rest-client-034 | network-retry-no-retry-after, retry-budget | Replies `timedOut`, 503, `timedOut`, 200 (derived) | Sleeps `[1 s, 2 s, 4 s]` from one shared counter; 4 requests. |
| gmail-rest-client-035 | reserve-before-each-attempt, quota-costs | Pacer 5 units per second, burst 0, stopped clock; `profile()` then `history(startHistoryId: "7", pageToken: nil)` (test `eachCallWaitsForTheQuotaItCosts`) | Recorded sleeps `[200 ms, 600 ms]`. |
| gmail-rest-client-036 | reserve-before-each-attempt | Replies 503 then 200 with pacer 5 units per second, burst 0, stopped clock, `profile()` (derived) | Sleeps `[200 ms, 1 s, 400 ms]`: the first pacing wait, the backoff, then the pacing wait for the retry. |
| gmail-rest-client-037 | token-once-per-call, bearer-header | A token closure that counts calls; replies 503 then 200 for `profile()` (derived) | The closure ran once; both requests carry the same `Authorization` value. |
| gmail-rest-client-038 | token-failure-propagates | A token closure that throws `IntegrationError.revoked`, `profile()` (derived) | Throws `IntegrationError.revoked`; zero requests. |
| gmail-rest-client-039 | invalid-url-error | `message(id: "a b")`, an id with a space, which is not a valid URL character (derived from the guard; no test). Every other path is fixed, so only an id can reach the guard, and only on an OS where `URLComponents(string:)` returns nil for it | Where the guard trips, throws `IntegrationError.gmail(status: 0, message: "Invalid URL for messages/a b")`; zero requests. |
| gmail-rest-client-040 | error-mapping | Reply 404 to `message(id: "m1")` with an empty body (derived) | Throws `IntegrationError.gmail(status: 404, message: HTTPURLResponse.localizedString(forStatusCode: 404))`; 1 request. |
| gmail-rest-client-041 | non-http-response | A stub session returning a plain `URLResponse` (derived) | Throws `IntegrationError.gmail(status: 0, ...)`; 1 request. |
| gmail-rest-client-042 | decode-failure, success-range | Reply 200 body `not json` to `profile()` (derived) | Throws `DecodingError`; 1 request; no sleep. |
| gmail-rest-client-043 | no-retry-other-status | Reply 401 `{"error":{"message":"Invalid Credentials"}}` (derived) | Throws `IntegrationError.gmail(status: 401, message: "Invalid Credentials")`; 1 request. |
| gmail-rest-client-044 | cancellation-propagates | The `sleep` closure throws `CancellationError`; replies 503 (derived) | The call throws `CancellationError`; 1 request sent. |
| gmail-rest-client-045 | base-url, query-only-when-present | `profile()` (derived from `sendsBearerToken`) | Request URL is `https://gmail.googleapis.com/gmail/v1/users/me/profile` with no `?`. |
| gmail-rest-client-046 | stateless-concurrent, pacer-injectable | Two concurrent `profile()` calls on one client, each answered 503 then 200, with a recording `sleep` (derived) | Both succeed; each records its own `1 s` backoff; the recorded sleeps hold the two `1 s` backoffs and four pacing waits of 200, 400, 600 and 800 ms in some order, when the pacer is 5 units per second with burst 0 and a stopped clock, so the pacer made four reservations of 1. |
| gmail-rest-client-047 | batch-modify-bounds, batch-modify-limit | `batchModify` with 1001 ids, then `profile()`, on a pacer of 5 units per second, burst 0 and a stopped clock, with a counting token closure (derived) | The first call throws `IntegrationError.gmail(status: 0, message: "batchModify takes 1–1000 ids, got 1001")`; zero requests; the token closure ran only for `profile()`; recorded sleeps are `[200 ms]` alone, so the rejected call reserved no quota. |

SHOULD requirements: none are stated in this ingredient, so none are left without a vector.

## Edge Cases

- **Null and empty input**: A listing reply with no `messages` yields an empty id list (MUST). A thread reply with no `messages` yields an empty message list (MUST). A `labels` reply with no `labels` yields an empty list (MUST). A `history` reply with no `history` yields empty `changedIds` and `deletedIds` (MUST). An empty `labelIds` sends no `labelIds` item (MUST).
- **Boundary values: batch size**: `batchModify` accepts 1 through 1000 ids; 0 and 1001 throw before any request (MUST). `searchMessageIds` passes `maxResults` through unchanged, so 0, a negative number or a number above Gmail's own page cap is sent as written and Gmail's response decides; the client does not clamp it. `listMessageIds` always sends 500.
- **Boundary values: retries**: The 7th attempt is the last; the 6th retry waits 32 seconds, the total backoff being 63 seconds (MUST). A `Retry-After` of 0 retries at once; one above 32 waits 32 seconds (MUST).
- **Boundary values: expired cursor**: A `history` 404 becomes `GmailCursorExpired` only on the `history` call; a 404 from any other operation is `IntegrationError.gmail(status: 404, ...)` (MUST).
- **Boundary values: history ids**: An id both added and deleted in the same page appears only in `deletedIds` (MUST). An id deleted on a later page and added on this one is not reconciled across pages; the client works one page at a time.
- **Error states: HTTP**: A 400, 401, 404 or non-rate-limit 403 is thrown at once as `IntegrationError.gmail` (MUST). A 401 is not retried and the access token is not refreshed here; refreshing is the job of whoever supplies the `accessToken` closure.
- **Error states: unreadable error body**: A failure body that is empty, not JSON or without `error.message` yields the system's status text, and a 403 with such a body is not treated as rate limiting (MUST). The failure is still thrown, so nothing is swallowed.
- **Error states: success body that does not decode**: A `DecodingError` is thrown as is and is not retried (MUST). It is not wrapped in `IntegrationError`.
- **Error states: non-HTTP response**: Reported as status 0 and not retried (MUST).
- **Error states: URL cannot be built**: Thrown as status 0 before any request (MUST).
- **Offline or disconnected state**: `notConnectedToInternet`, `networkConnectionLost`, `timedOut` and `cannotConnectToHost` are retried up to 6 times over about 63 seconds and then thrown as the `URLError` (MUST). Other `URLError` codes, including `cannotFindHost`, fail on the first attempt. The client never queues or resumes work after it throws.
- **Concurrent access**: The class holds no mutable state; parallel calls are independent except that they share one `GmailQuotaPacer` actor, which serialises reservations (MUST). The default `shared` pacer is process-wide, so concurrent syncs of several accounts slow each other without ever exceeding quota.
- **Cancellation**: Cancelling the surrounding task makes `Task.sleep` throw `CancellationError`, which ends a retry or pacing wait (MUST). The in-flight `URLSession.data(for:)` call follows structured cancellation as `URLSession` defines it; that is not specified by this client.
- **Silent retries**: A call can wait about 63 seconds in backoff, plus any pacing wait, while retrying, and nothing is logged or reported during it; the Design Decision on retry visibility records this.
- **Timeouts**: The client sets no timeout of its own; a request lasts as long as the injected `URLSession` allows, and a timeout the session raises is a retried `timedOut` error.
- **Token expiry during retries**: The token is read once per call, so a token that expires during the retry window is not refreshed for that call; a later 401 is thrown, not retried.
- **Non-idempotent retry**: `batchModify` is a POST with no idempotency key and is retried on 429, 5xx, rate-limit 403 and transient network errors; Gmail's label add and remove are set operations, so applying the same `batchModify` twice leaves the same end state and a retry after a lost reply is harmless; the Design Decision on `batchModify` retry records this.
- **Retry-After forms**: An HTTP-date or any non-integer `Retry-After` is ignored (MUST); a value with surrounding spaces is trimmed before parsing (MUST).
- **Path ids**: `thread(id:)` and `message(id:)` interpolate `id` into the URL path with no validation or percent-encoding, so an id containing `/`, `?` or `#` changes the route or query instead of failing, and the invalid-URL guard catches only strings that `URLComponents` rejects. Ids come from Gmail responses, where they are opaque hexadecimal, and the client does not check that. A port may validate or encode them; the Design Decision on path ids records the choice.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `session` | `URLSession` | `.shared` | The transport. Supplies the request timeout and TLS behavior; tests pass a stubbed session. |
| `sleep` | `@Sendable (Duration) async throws -> Void` | `Task.sleep(for:)` | Waits out a pacing delay or a backoff. Injected so tests record delays. |
| `pacer` | `GmailQuotaPacer` | `.shared` | Reserves quota per attempt; `shared` runs 200 units per second with a 200-unit burst for the whole process. |
| `accessToken` | `@Sendable () async throws -> String` | none (required) | Returns a fresh bearer token each time a request is built. |

Constants the caller cannot set; a port keeps them fixed and does not expose them as options.

| Constant | Type | Value | Description |
|----------|------|-------|-------------|
| `baseURL` | `String` (private) | `https://gmail.googleapis.com/gmail/v1/users/me/` | Prefix of every request. |
| `maxRetries` | `Int` (internal) | `6` | Retries per call after the first attempt. |
| `baseDelay` | `Duration` (private) | 1 second | Backoff start; doubles per retry. |
| `maxDelay` | `Duration` (private) | 32 seconds | Cap for any backoff, including a `Retry-After` value. |
| `batchModifyLimit` | `Int` (public) | `1000` | Most ids per `batchModify` call. |
| `transientCodes` | `Set<URLError.Code>` (private) | `timedOut`, `networkConnectionLost`, `notConnectedToInternet`, `cannotConnectToHost` | Network errors that are retried. |
| `listMessageIds` page size | `Int` (literal) | `500` | Sent as `maxResults`; `searchMessageIds` takes it from the caller. |

There are no environment variables or settings keys.
## Deep Linking

Not applicable: the client only calls fixed Gmail API paths and defines no URL scheme or route of its own.

## Localization

The client emits two hardcoded English strings and one system-localised string; server text passes through untranslated.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none (hardcoded) | `Invalid URL for <path>` | `IntegrationError.gmail` message when the URL cannot be built. |
| none (hardcoded) | `batchModify takes 1–1000 ids, got <count>` | `IntegrationError.gmail` message from the bounds guard; the dash is an en dash. |
| `HTTPURLResponse.localizedString(forStatusCode:)` | system text for the status | Message used when an error body has no `error.message`; localised by the operating system. |

Gmail's own `error.message` is shown as received, in whatever language Google returns. Turning `IntegrationError` into display text happens in `IntegrationError.errorDescription`, outside this client.

## Accessibility Options

Not applicable: the client has no display and responds to no accessibility setting.

## Feature Flags

Not applicable: the source reads no flag and has no switchable behavior beyond constructor injection.

## Analytics

Not applicable: the source emits no analytics event.

## Privacy

- **Data collected**: The client handles the user's Gmail data (message ids, thread and message contents, labels, the address from `profile`) and a bearer token that grants access to it; it collects nothing beyond what an operation returns.
- **Storage**: None. The token and every response are held only for the duration of a call; the client has no cache, file or database. Where results and tokens are stored is for the callers (the Keychain and the mail store are separate components).
- **Transmission**: Every request goes over HTTPS to `gmail.googleapis.com` with the token in the `Authorization` header and no other third party. A `q` search string and label ids are sent in the URL query, and message ids in the path.
- **Retention**: None in this client. It writes no log, so tokens and message text do not appear in any log it produces.

## Logging

Not applicable: the source makes no log call; failures are thrown, never logged. Retries and backoff waits leave no trace. See the Design Decision on logging.
## Platform Notes

- **SwiftUI**: Not a view, so nothing to translate. A SwiftUI app depends on the `GmailAPI` protocol and a view model awaits the operations from a `.task` modifier or a model method; tests substitute a fake `GmailAPI`. A cancelled `.task` cancels the retry wait through `Task.sleep`.
- **Compose**: Port as a Kotlin class implementing a `GmailApi` interface over OkHttp or Ktor. Use `suspend` functions, `kotlinx.coroutines.delay` for the pacing and backoff waits (injected as a `suspend (Duration) -> Unit`), and a `kotlinx.coroutines.sync.Mutex` around a `System.nanoTime` based reservation in place of the `actor`. Map `SocketTimeoutException`, `ConnectException` and `UnknownHostException` to the transient set (note that `UnknownHostException` also covers offline, which the source splits between `notConnectedToInternet` and `cannotFindHost`, the latter not retried); `kotlinx.serialization` replaces `JSONDecoder`; `Response.header("Retry-After")?.trim()?.toIntOrNull()` matches the integer-only rule. Throw a `GmailException(status, message)` for `IntegrationError.gmail` and a distinct exception for `GmailCursorExpired`. Coroutine cancellation (`CancellationException`) must not be swallowed by a retry `catch`.
- **React/Web**: Port as a TypeScript class over `fetch` with an `async` method per operation and an injected `sleep: (ms: number) => Promise<void>` (`setTimeout` in a promise, honouring an `AbortSignal`). Build the URL with `URL` and `URLSearchParams.append` so repeated `historyTypes` and `labelIds` keys are kept in order; read `Retry-After` with `response.headers.get` and parse it with a trimmed `Number.parseInt` guard. A failed `fetch` rejects with a bare `TypeError` that does not say timeout versus offline, so treat every network `TypeError` as transient (the source retries only four codes) and apply timeouts with `AbortSignal.timeout`. JavaScript is single-threaded, so the pacer needs no lock, only a monotonic clock such as `performance.now()`. Browser CORS and token storage are the caller's concern.
- **AppKit / UIKit**: Source platform. The code is `packages/apple/AgenticDeveloperHubSDK/Integrations/Gmail/GmailRESTClient.swift`, with its protocol and wire types in `GmailAPI.swift` and the pacer and quota costs in `GmailQuotaPacer.swift` (`GmailQuotaPacer` is a `public actor` over `ContinuousClock`; `GmailQuotaCost` is an internal enum). It uses Foundation only: `URLSession.data(for:)`, `URLComponents` and `URLQueryItem` (the framework percent-encodes query values), `URLError.Code`, `JSONDecoder` and `JSONEncoder`, `HTTPURLResponse.value(forHTTPHeaderField:)` and `Duration` (macOS 13 and iOS 16 or later). The class is `final` with only `let` properties of `Sendable` types, so it is `Sendable` through `GmailAPI`. `IntegrationError` is in `Integrations/Model/IntegrationError.swift`. `MailIntegrationService` constructs the client with `GmailRESTClient(accessToken:)` and chunks `batchModify` by `batchModifyLimit`. Tests are in `Tests/AgenticDeveloperHubSDKIntegrationsTests/GmailRESTClientTests.swift` over a `StubURLProtocol`.
- **WinUI 3**: Write a `sealed class GmailRestClient : IGmailApi` in C# over a long-lived `HttpClient` (inject it from `IHttpClientFactory`, not one per call). Build each `HttpRequestMessage` with `Uri` and `System.Web` or `Microsoft.AspNetCore.WebUtilities.QueryHelpers.AddQueryString` (append repeated keys for `historyTypes` and `labelIds`), set `request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token)`, and obtain the token from an injected `Func<CancellationToken, Task<string>>` once per call. `HttpClient` does not throw on a non-success status, so read `response.StatusCode` yourself instead of calling `EnsureSuccessStatusCode`. Because an `HttpRequestMessage` can be sent only once, rebuild or clone it on each retry while reusing the same token string. Map `HttpRequestException` (with `HttpRequestError.ConnectionError` or `NameResolutionError` on .NET 8 and later) and a `TaskCanceledException` caused by `HttpClient.Timeout` to the transient set, and tell a caller cancellation apart by checking `cancellationToken.IsCancellationRequested`; `HttpClient.Timeout` defaults to 100 seconds, whereas `URLSession.shared` allows 60. Read `Retry-After` through `response.Headers.RetryAfter?.Delta?.TotalSeconds` and ignore its `Date` form, to match the integer-only rule. Wait with `await Task.Delay(TimeSpan, cancellationToken)` (injected as a `Func<TimeSpan, CancellationToken, Task>`), clamp with `TimeSpan` arithmetic and `Math.Min`, and use `Stopwatch.GetTimestamp` as the monotonic clock. Replace the `GmailQuotaPacer` actor with a class guarded by a `SemaphoreSlim(1, 1)` or a `lock` around the reservation arithmetic, returning a `TimeSpan`. Parse with `System.Text.Json` (`JsonSerializer.Deserialize<T>` with `[JsonPropertyName]` and nullable members, and `JsonDocument` with `TryGetProperty` for the error envelope so a malformed body yields false instead of an exception); `JsonException` replaces `DecodingError`. Send the batchModify body with `new StringContent(json, Encoding.UTF8, "application/json")`, which adds `; charset=utf-8` to the `Content-Type`, unlike the source's bare `application/json`. Use a `GmailException(int Status, string Message)` for `IntegrationError.gmail` and a separate `GmailCursorExpiredException`. The service is stateless, so register it as a singleton with `AddHttpClient`; no `ObservableCollection` or `INotifyPropertyChanged` belongs in it.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Integrations/Gmail/GmailRESTClient.swift` | unverified |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Retry covers 429, every 5xx, a 403 that names a rate limit, and four transient network codes; every other status and error fails at once.
**Rationale**: The doc comment on `isRateLimited` states that Gmail reports an exceeded quota as a 403 as well as a 429, and "any other 403 is a real refusal and is not retried". Retrying a permission 403 would only delay a failure that cannot succeed.
**Approved**: pending

**Decision**: Backoff starts at 1 second, doubles and is capped at 32 seconds, with 6 retries.
**Rationale**: The class comment says the retries should "span the minute Gmail's quota is counted over": 1+2+4+8+16+32 is 63 seconds. A `Retry-After` value is honoured but also capped at 32 seconds, so a server asking for a longer wait is not obeyed.
**Approved**: pending

**Decision**: The pacer is consulted before every attempt, retries included, and cost is reserved before the request goes out.
**Rationale**: The class comment says each attempt reserves its cost so "a sync stays under Gmail's per-user rate limit instead of tripping it"; a retry spends quota too. The pacer and the sleep function are injected so tests drive time.
**Approved**: pending

**Decision**: `Retry-After` is read only as whole seconds; an HTTP-date is ignored.
**Rationale**: The code parses the header with `Int(...)` after trimming, so any other form falls back to exponential backoff. A port that honoured dates would wait differently from the source.
**Approved**: pending

**Decision**: Technical debt: the access token is read once per call and reused for every retry.
**Rationale**: The request is built before the retry loop, so a token that expires during up to 63 seconds of backoff plus pacing is not renewed for that call, and a 401 is thrown instead of retried. Whoever supplies the closure owns refreshing. The class comment says the closure supplies a fresh token "per request", which holds per call, not per attempt.
**Approved**: pending

**Decision**: `batchModify` rejects an empty or oversized list with status 0 and leaves chunking to the caller.
**Rationale**: The source comment calls such a list "a caller bug, not a Gmail call". Status 0 marks an error raised locally rather than returned by Google. `MailIntegrationService` chunks by `batchModifyLimit`.
**Approved**: pending

**Decision**: A 404 from `history` becomes `GmailCursorExpired`, and an id both changed and deleted is reported only as deleted.
**Rationale**: The `GmailCursorExpired` doc comment says a 404 means the cursor is older than Gmail keeps and a full sync is needed. Reporting a deleted id as changed would make the engine fetch a message that no longer exists. Label additions and removals count as changes because they alter the stored message.
**Approved**: pending

**Decision**: Listing ids are deduplicated in first-seen order.
**Rationale**: The source applies `unique` without saying why, and test `listMessageIdsDedupesAndToleratesEmpty` fixes the behavior; a port must keep it. The reason is not recorded in the source.
**Approved**: pending

**Decision**: A decode failure, a non-HTTP response and a URL failure are not retried. Technical debt: a decode failure is thrown as a `DecodingError` rather than an `IntegrationError`.
**Rationale**: Only a failure that a later attempt could change is retried. The inconsistent error type is what the code does, so a caller catching only `IntegrationError` misses a malformed success body. A port should wrap it as `IntegrationError.gmail(status: <code>, ...)` so one catch covers every failure.
**Approved**: pending

**Decision**: The client sets no timeout and has no cancellation handling beyond `Task.sleep` and the `URLSession` default.
**Rationale**: Nothing in the source configures a `timeoutInterval`, so timeouts come from the injected session and surface as retried `timedOut` errors. Behavior on a stalled connection is the session's.
**Approved**: pending

**Decision**: `batchModify` is retried like every other call, although it is a POST with no idempotency key.
**Rationale**: Adding or removing a label that is already in that state changes nothing in Gmail, so a repeat after a lost reply or a 5xx leaves the same end state as one application. The code retries on 429, 5xx, rate-limit 403 and the four transient network errors without a separate rule for this call. An operation that is not idempotent in a port must be excluded from network-error retries.
**Approved**: pending

**Decision**: Ids interpolated into `threads/<id>` and `messages/<id>` are not validated or percent-encoded.
**Rationale**: The ids come from Gmail's own listing and history responses, which are opaque hexadecimal strings, so the source trusts them; an id such as `a/b` would change the route instead of failing. Input sanitization is therefore partial in Compliance. A port may encode the segment, at no cost to ids Gmail issues.
**Approved**: pending

**Decision**: The client never logs and offers no retry or backoff hook.
**Rationale**: The source has no log call and no callback, so a stalled call of up to about 63 seconds of backoff shows nothing to an observer, and the token and query cannot leak into a log. Anyone who needs visibility injects a `sleep` closure that records each wait, which is how the tests observe retries. A port that adds a retry event must leave out the token and the query.
**Approved**: pending
## Compliance

| Check | Status | Category | Notes |
|-------|--------|----------|---|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices | Only shapes requests and maps responses; quota arithmetic is in `GmailQuotaPacer`, token supply with the caller, parsing in `GmailMessageParser`, chunking in the service. |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices | `GmailRESTClientTests` covers every operation except `message(id:)` and `labels()`, plus retry, backoff, rate-limit, pacing and batch bounds; not token failure, an invalid URL, a non-HTTP response, a non-integer or negative `Retry-After`, a decode failure, a 401, the shared retry counter or concurrent calls (vectors 007, 010, 011, 013, 014, 018 to 020, 029, 032 to 034 and 036 to 047 are derived). |
| [adc.check.access-patterns.retry-with-backoff](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bcb17bfe-d2d6-53f3-b2af-06b7eea3da61) | passed | access-patterns | Retries are bounded at 6 and backoff is capped at 32 seconds. |
| [adc.check.access-patterns.rate-limit-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/aed555ee-66e3-5f99-88ab-24674ed5c789) | passed | access-patterns | A quota 403 is told apart from a refusal and retried. |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | passed | access-patterns | Every failure is thrown; none is swallowed. |
| [adc.check.access-patterns.timeout-configuration](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dc15eb62-a72c-5b09-b9e7-c1bed983f499) | partial | access-patterns | The client sets no timeout and relies on the injected session. |
| [adc.check.access-patterns.pagination-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/e29ce31a-67cb-5690-b2ca-b1065ccdaf1a) | passed | access-patterns | Page tokens go out and come back unchanged. |
| [adc.check.security.secure-transport](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0a75f61f-9508-506e-b92e-0f5b29a91c95) | passed | security | The base URL is fixed HTTPS. |
| [adc.check.security.token-lifecycle](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/61edfc73-f26a-5cfa-8c09-d1011eb8b7cd) | partial | security | The token is read once per call and never refreshed or revoked by this client. |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | security | Path ids are not validated or encoded; see the Design Decision on path ids. |
| [adc.check.privacy-and-data.no-pii-in-logs](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/23bca2e1-dc0f-5ff4-beaf-03891ad48e6b) | passed | privacy-and-data | The source never logs. |
## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
