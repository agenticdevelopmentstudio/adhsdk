---
id: 18871853-95b7-492a-9f1f-417283594824
title: "Gmail API"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-13
modified: 2026-11-13
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The slice of the Gmail REST API the mail sync engine uses: a fakeable protocol, its wire shapes, the expired-cursor error and the full-sync query builder."
platforms:
  - swift
  - macos
  - ios
tags:
  - gmail
  - mail-sync
  - api-client
depends-on:
  - df121975-deb8-49a9-b023-0aadcb0923d8
  - 351e3bf8-b137-4f59-94de-c769aa8b0666
related:
  - c448c9f4-195d-4625-a49d-22dd5468a914
  - aed9acc9-6340-487b-acfb-b7b13f14e59a
  - cdadfe1d-e4a2-4e2d-96a7-a5eb615a1302
  - ea7a9ec6-0a0c-4e97-8b03-ebc5f6246a43
references:
  - https://developers.google.com/gmail/api/reference/rest/v1/users.messages/list
  - https://developers.google.com/gmail/api/reference/rest/v1/users.history/list
  - https://developers.google.com/gmail/api/reference/rest/v1/users.messages/batchModify
  - https://support.google.com/mail/answer/7190
approved-by: ""
approved-date: ""
---

# Gmail API

## Overview

`GmailAPI` is the narrow protocol through which the mail sync engine talks to Gmail: profile, message-id listing, search, thread and message fetch, history, labels and label changes. The file also holds the decoded wire shapes (`GmailProfile`, `GmailIdPage`, `GmailThreadDTO`, `GmailHistoryPage`, `GmailHeader`, `GmailBody`, `GmailPart`, `GmailMessageDTO`, `GmailLabelDTO`), the `GmailCursorExpired` error, and `GmailQuery`, which builds the `messages.list` query for a full sync. The protocol's own comment states the design intent: "Small so tests can fake it." The concrete HTTP implementation is `GmailRESTClient`, a separate file; this ingredient specifies the contract; `GmailRESTClient` has its own ingredient. Use it wherever sync code needs Gmail data without depending on HTTP.

## Behavioral Requirements

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

## Appearance

Not applicable — this is a data-access protocol and set of wire types, not a visual component.

## States

Not applicable — this is a data-access protocol and set of wire types, not a visual component. The protocol holds no state; `GmailQuery` is a stateless enum with one static function.

## Accessibility

Not applicable — this is a data-access protocol and set of wire types, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| gmail-api-001 | full-sync-after, full-sync-class-filter, full-sync-include-flag | `fullSync(settings: .default, now: Date(timeIntervalSince1970: 1_730_800_000))`; default is 30 days, nothing included (test `fullSyncQueryDefault`) | query `after:<1730800000 - 30*86400> {in:inbox in:sent in:drafts is:starred has:userlabels}`, `includeSpamTrash` false |
| gmail-api-002 | full-sync-spam-trash-terms, full-sync-include-flag | `includeSpam` and `includeTrash` true, `windowDays` 1, `now` is `Date(timeIntervalSince1970: 1_730_800_000)` (test `fullSyncQueryWithSpamAndTrash`) | query `after:<1730800000 - 86400> {in:inbox in:sent in:drafts is:starred has:userlabels in:spam in:trash}`, `includeSpamTrash` true |
| gmail-api-003 | full-sync-archived, full-sync-include-flag | `includeArchived` and `includeSpam` true, `windowDays` 2, `now` is `Date(timeIntervalSince1970: 1_730_800_000)` (test `fullSyncQueryArchivedDropsClassFilter`) | query exactly `after:<1730800000 - 2*86400>`, `includeSpamTrash` true |
| gmail-api-004 | cursor-expired | `history` against a server answering 404 (test `historyNotFoundThrowsCursorExpired`) | throws `GmailCursorExpired` |
| gmail-api-005 | thread-messages-optional | decode `{"id":"t1"}` as a thread (test `aThreadWithNoMessagesDecodesEmpty`) | `id` is `t1`, `messages` is empty |
| gmail-api-006 | batch-modify | `batchModify(ids: ["a"], add: ["STARRED"], remove: ["INBOX"])` (test `batchModifyPostsBody`) | one POST with body `ids ["a"]`, `addLabelIds ["STARRED"]`, `removeLabelIds ["INBOX"]` |
| gmail-api-007 | batch-modify-limits | empty `ids`, then 1001 ids (test `batchModifyRejectsEmptyAndOversizedListsWithoutCallingGmail`) | each throws `IntegrationError`; zero requests sent |
| gmail-api-008 | history-page | a history response with changed and deleted entries (test `historyPageCollectsChangedAndDeleted`) | `changedIds`, `deletedIds`, `historyId` and `nextPageToken` populated from the response |
| gmail-api-009 | thread-id-required | decode `{"messages":[]}` as a thread (no test yet) | decoding throws |
| gmail-api-010 | failure-surfaces, no-error-translation-here | `profile()` against a 403 with message `Insufficient Permission` (test `errorBodyMessageSurfaces`) | throws `IntegrationError.gmail(status: 403, message: "Insufficient Permission")`, one request, no retry |
| gmail-api-011 | message-shape | decode `{"id":"m","threadId":"t"}` as a message (no test yet) | succeeds; all optional fields are nil |
| gmail-api-012 | label-shape | decode `{"id":"L","name":"n"}` as a label (no test yet) | decoding throws because `type` is missing |

## Edge Cases

- **empty-thread**: A thread with no `messages` key MUST decode to an empty `messages` array, not fail.
- **empty-listing**: A listing with no messages MUST yield a `GmailIdPage` with empty `ids`; `GmailRESTClient` tolerates a missing `messages` key and de-duplicates ids (test `listMessageIdsDedupesAndToleratesEmpty`).
- **expired-cursor**: A 404 on `history` MUST throw `GmailCursorExpired` and not a generic error, so the caller can fall back to a full sync.
- **other-404**: A 404 on any other operation is not translated by this contract; it surfaces as the implementation's error.
- **window-days-boundary**: `fullSync` applies no clamping; `MailSyncSettings` documents `windowDaysRange` as 1 through 3650, and enforcement belongs to that type. A `windowDays` of 0 yields an `after:` equal to `now`.
- **sub-second-now**: `fullSync` truncates `now` to whole seconds through `Int`.
- **archived-with-spam**: With `includeArchived` true, `includeSpam` and `includeTrash` add no query terms but still set `includeSpamTrash`, so the listing call includes spam and trash.
- **batch-oversize**: More than 1000 ids MUST be rejected before any request.
- **malformed-wire**: Missing required fields (`id`, `threadId`, `name`, `type`, `emailAddress`, `historyId`) cause decoding to throw; the contract does not recover.
- **concurrent-calls**: The protocol is `Sendable`, so callers MAY invoke operations concurrently; it states no ordering rule, and a fake or client decides its own serialization. `GmailRESTClient` paces calls against a quota (test `eachCallWaitsForTheQuotaItCosts`).
- **offline**: A network failure surfaces as a thrown error from the implementation; the contract defines no offline mode. `GmailRESTClient` retries transient network errors and fails fast on non-transient ones (test `nonTransientNetworkErrorsAreNotRetried`).
- **cancellation**: The protocol declares no cancellation behavior; the contract does not say whether a cancelled task must throw `CancellationError`, so it is left to the implementation.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `settings` | `MailSyncSettings` | `.default` | Input to `GmailQuery.fullSync`: `includeArchived` false, `includeSpam` false, `includeTrash` false, `windowDays` 30, `pollIntervalMinutes` 15 (only `includeArchived`, `includeSpam`, `includeTrash` and `windowDays` affect the query) |
| `now` | `Date` | none | Clock injected into `GmailQuery.fullSync` so tests are deterministic |
| `query` | `String` | none | Gmail search syntax passed to `listMessageIds` and `searchMessageIds` |
| `maxResults` | `Int` | none | Page size parameter of `searchMessageIds` only |
| list page size | `Int` | 500 | Not a protocol parameter: `GmailRESTClient.listMessageIds` has no `maxResults` argument and always requests 500 ids per page |
| `accessToken` | `@Sendable () async throws -> String` | none | Token supplier passed to the `GmailRESTClient` initializer, not to the protocol; called for each request |

## Deep Linking

Not applicable: the file defines a protocol and wire types and exposes no URLs or routes.

## Localization

Not applicable: the file contains no user-facing strings; the only strings are Gmail search tokens and wire field names, which are not localized.

## Accessibility Options

Not applicable: the file has no visual output and responds to no display option.

## Feature Flags

Not applicable: the file reads no flag; query behavior depends only on the `MailSyncSettings` values passed in.

## Analytics

Not applicable: the file emits no events.

## Privacy

- **Data collected**: The types carry the user's Gmail address, message ids, headers, snippets, bodies, attachment ids and label names, read from Gmail on behalf of the signed-in user.
- **Storage**: None in this file; the DTOs are transient decoded values. What the sync engine mirrors is decided by `MailClassifier`, outside this file.
- **Transmission**: The protocol's implementation sends requests to Gmail; `batchModify` writes label changes back to Gmail. This file itself does no I/O.
- **Retention**: Not applicable in this file; retention belongs to the store that receives the data.

## Logging

Not applicable: the file contains no log calls.

## Platform Notes

- **SwiftUI**: Not a view; a SwiftUI app consumes it through a service or model that holds a `GmailAPI`. The protocol and the DTOs conform to `Sendable`, and the DTOs are value types, so they can be passed to `@MainActor` view models. Source file: `GmailAPI.swift`, in the Integrations/Gmail folder; the implementation is `GmailRESTClient.swift` beside it.
- **Compose**: Define a Kotlin interface with `suspend` functions for the protocol, `data class` types decoded with kotlinx.serialization (`@Serializable`, nullable fields with defaults, `ignoreUnknownKeys`), and a custom error `class GmailCursorExpired : Exception()`. Use Retrofit or Ktor for HTTP and a `ViewModel` coroutine scope for calls. Differs from the source: the Swift `Sendable` guarantee has no Kotlin equivalent.
- **React/Web**: Define a TypeScript interface returning Promises, with `interface` types for the DTOs and a `class GmailCursorExpired extends Error`. Base64url data decodes with a manual replace of `-` and `_` before `atob`. `GmailQuery.fullSync` is a pure function taking a settings object and a `Date`, using `Math.floor(ms / 1000)`.
- **AppKit / UIKit**: Same Swift types as the source on macOS and iOS; it uses only Foundation, so no platform branching is needed. Tests fake `GmailAPI` with a struct or actor conforming to the protocol, as the source's test support does.
- **WinUI 3**: Define `interface IGmailApi` with `Task<T>` methods taking a `CancellationToken`; model the DTOs as C# `record` types deserialized with `System.Text.Json` (`JsonSerializerOptions` with `PropertyNameCaseInsensitive`, nullable reference types for optional fields, and a custom `JsonConverter` or default-initialized property so a missing `messages` yields an empty list). `GmailCursorExpired` becomes a sealed `Exception` subclass. Implement the REST client with `HttpClient` plus a `DelegatingHandler` for the bearer token, retry with exponential backoff capped at 32 seconds, and rate pacing; `Retry-After` is read from `HttpResponseMessage.Headers.RetryAfter`. Base64url bodies decode with `Convert.FromBase64String` after replacing `-` and `_` and padding. Keep the query builder a static class with `DateTimeOffset.ToUnixTimeSeconds()`. Tokens persist in `Windows.Security.Credentials.PasswordVault`; sync work runs in a background `Task` or an `IHostedService`. Differs from the source: there is no `Sendable` compile-time check, so keep DTOs immutable `record` types.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Integrations/Gmail/GmailAPI.swift` | unverified |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

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

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.access-patterns.pagination-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/e29ce31a-67cb-5690-b2ca-b1065ccdaf1a) | passed | access-patterns |
| [adc.check.access-patterns.rate-limit-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/aed555ee-66e3-5f99-88ab-24674ed5c789) | partial | access-patterns |
| [adc.check.security.token-lifecycle](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/61edfc73-f26a-5cfa-8c09-d1011eb8b7cd) | partial | security |

Separation of concerns passes because the file holds only the contract, wire types and query builder, while HTTP, retry, pacing and classification live in `GmailRESTClient` and `MailClassifier`. Unit-test coverage is partial: the query builder, the expired cursor, the empty thread and batch limits all have tests, in `GmailMessageParserTests` and `GmailRESTClientTests`, but vectors gmail-api-009, gmail-api-011 and gmail-api-012 (required `id`, optional message fields, required label `type`) have no test. Explicit error handling passes because the one actionable failure has its own type and the rest throw. Pagination passes because both listing results and history carry `nextPageToken`. Rate-limit handling and token lifecycle are partial: this file declares neither, and the behavior lives in `GmailRESTClient` and in whatever supplies its access token, outside the file this ingredient covers.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
