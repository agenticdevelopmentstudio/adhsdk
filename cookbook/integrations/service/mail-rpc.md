---
id: fc9671be-170c-436e-9628-892624952191
title: "MailRPC"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-13
modified: 2026-11-13
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The mail service wire contract: MailRequest and MailResponse, their record types, MailMessageFilter, and MailClient, which checks that an older service honored each filter."
platforms:
  - swift
  - macos
tags:
  - mail
  - rpc
  - gmail
  - integrations
depends-on: []
related:
  - aed9acc9-6340-487b-acfb-b7b13f14e59a
  - be4db0fe-628d-41f8-9fdf-25a6d46844cf
  - cbee8b02-9456-4d9b-942a-51f8a9c074fc
  - 3d12c073-edc3-44fb-a988-5edec20575e0
references: []
approved-by: ""
approved-date: ""
---

# MailRPC

## Overview

`MailRPC.swift` is the contract between a host and the mail integration service. It holds the request and response enums, the records they carry, and `MailClient`, a thin client that sends one request over any byte transport and turns the reply into a typed value or a thrown error.

- `MailRequest` lists every operation a caller can ask for, including the ones that administer the integration (the OAuth client, accounts, sign-in, sync settings) and the ones that read or label mail.
- `MailResponse` lists every reply, including `.failure`, which carries an optional `notFound` flag.
- `MailMessageFilter` describes which messages to list and clamps its `limit` to 1 through 500.
- `MailAccount`, `MailProviderStatus`, `MailLabel`, `MailMessage`, `MailMessagePage`, `MailThread` and `MailMoveResult` are the records the replies carry.
- `MailClient` is the caller's side: it encodes a request to JSON, decodes the reply, throws `MailClientError` for a `.failure`, refuses a page that an older service answered without honoring the filter, and reports a thread request that an older service cannot decode as a service too old to show threads.

The service side ([MailIntegrationService](cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a)) is outside this file and answers these requests; the transport is injected, so the same client works over XPC, a socket or in-process.

## Behavioral Requirements

### MailRequest

- **request-cases**: `MailRequest` MUST offer exactly these cases: `providerStatus`, `importOAuthClient(json:)`, `removeProvider`, `listAccounts`, `signIn`, `cancelSignIn`, `removeAccount(account:)`, `updateSettings(account:settings:)`, `syncNow(account:)`, `listLabels(account:)`, `listMessages(_:)`, `getMessage(account:id:)`, `getThread(account:id:includeBodies:)`, `modifyLabels(account:messageIds:add:remove:)` and `moveMessages(account:messageIds:destination:from:)`.
- **request-conformances**: `MailRequest` MUST be `Codable`, `Sendable` and `Equatable`, and so MUST `MailResponse` and every record type in this file.
- **request-account-argument**: Every `account` argument MUST accept either a connection id or an email address (the type's own comment).
- **request-sign-in-exclusive**: `signIn` is declared to run the browser flow in the service's process and to be refused while another sign-in is pending (the case's comment); the service ([MailIntegrationService](cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a)) enforces it, and this file only declares it.
- **request-cancel-sign-in**: `cancelSignIn` is declared to end a pending sign-in, which then answers "Sign-in was cancelled", and to be harmless when none is pending (the case's comment); the service ([MailIntegrationService](cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a)) enforces it.
- **request-sync-all**: `syncNow` with a `nil` account is declared to sync every account (the case's comment); the service ([MailIntegrationService](cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a)) does the syncing.
- **request-message-id**: `getMessage` MUST accept either this system's message id or Gmail's (the case's comment).
- **request-thread-id**: `getThread` is declared to take a Gmail thread id, or a message id (this system's or Gmail's) that stands for the thread it is in; the service ([MailIntegrationService](cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a)) reads the conversation from Gmail, oldest message first (the case's comment).
- **request-modify-labels-ids**: `modifyLabels` MUST name messages by this system's id or Gmail's, and labels by Gmail label id or exact name (the case's comment).
- **request-move-semantics**: `moveMessages` is declared to add `destination` and remove every label in `from`; a `nil` `from` means INBOX, or nothing when `destination` is INBOX, and an empty `from` removes nothing (the case's comment). The service ([MailIntegrationService](cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a)) applies this rule; this file only declares it.
- **request-wire-form**: A request MUST travel as the JSON that the synthesized `Codable` conformance produces for the enum; the tests decode replies such as `{"messages":{"_0":{"messages":[]}}}` and `{"failure":{"_0":"boom"}}`, which show the form for a case with one unlabeled payload.

### isMailboxAccess

- **mailbox-access-true**: `isMailboxAccess` MUST be true for `listAccounts`, `listLabels`, `listMessages`, `getMessage`, `getThread`, `modifyLabels` and `moveMessages`.
- **mailbox-access-false**: `isMailboxAccess` MUST be false for `providerStatus`, `importOAuthClient`, `removeProvider`, `signIn`, `cancelSignIn`, `removeAccount`, `updateSettings` and `syncNow`.
- **mailbox-access-purpose**: `isMailboxAccess` MUST be true exactly for the requests that read or label mail in accounts already signed in, which is everything [MailCommandLine](cookbook:be4db0fe-628d-41f8-9fdf-25a6d46844cf) and [MailToolSource](cookbook:cbee8b02-9456-4d9b-942a-51f8a9c074fc) send; the false side is what a host keeps for its own UI.
- **mailbox-access-exhaustive**: The classification MUST be an exhaustive switch with no default, so a new request cannot compile until it is placed on one side.

### MailMessageFilter

- **filter-fields**: `MailMessageFilter` MUST carry `account` (required), `since`, `until`, `labels`, `anyLabels`, `limit`, `cursor`, `includeBodies` and `query`.
- **filter-since-until**: `since` and `until` are declared as inclusive ISO-8601 strings (the type's comment). They are stored as plain `String` and this file does not parse or validate them; see the Design Decision on raw date text.
- **filter-labels-and**: A listed message MUST carry every entry of `labels`, given as ids or names (the type's comment).
- **filter-any-labels-or**: When `anyLabels` is not empty, a listed message MUST also carry at least one entry of `anyLabels`.
- **filter-cursor**: `cursor` MUST be the `nextCursor` of the previous page.
- **filter-query-gmail**: With a `query`, the messages MUST come from a Gmail search instead of the synced copy, so they reach past the sync window and the synced classes; the query is Gmail's search syntax (`from:greenhouse`).
- **filter-query-narrowing**: With a `query`, `since`, `until` and `labels` are declared to narrow it (the type's comment); the service ([MailIntegrationService](cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a)) applies them.
- **filter-query-any-labels-refused**: With a `query`, a non-empty `anyLabels` is declared to be refused by the service ([MailIntegrationService](cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a)); the caller writes `{label:a label:b}` in the query instead (the type's comment).
- **filter-limit-range**: `MailMessageFilter.limitRange` MUST be 1 through 500 and `defaultLimit` MUST be 50.
- **filter-limit-clamp-init**: The initializer MUST clamp `limit` into `limitRange`.
- **filter-limit-clamp-set**: Assigning `limit` after construction MUST clamp it into `limitRange` through a `didSet` observer.
- **filter-decode-lenient**: Decoding MUST require only `account`; `labels` and `anyLabels` default to empty, `limit` to 50, `includeBodies` to false, and `since`, `until`, `cursor` and `query` to nil.
- **filter-decode-clamps**: Decoding MUST route `limit` through the initializer, so a decoded out-of-range `limit` is clamped.
- **filter-encode-keys**: Encoding MUST use the coding keys `account`, `since`, `until`, `labels`, `anyLabels`, `limit`, `cursor`, `includeBodies` and `query`.
- **filter-search-query**: `searchQuery` MUST return `query` with surrounding whitespace and newlines trimmed, and nil when `query` is nil or trims to an empty string.

### Records

- **account-record**: `MailAccount` MUST carry `id`, `email`, `status` (a `ConnectionStatus`), `lastSyncAt`, `lastError` and `settings` (a `MailSyncSettings`); `lastSyncAt` and `lastError` are optional.
- **provider-status-record**: `MailProviderStatus` MUST carry `configured`, an optional `clientId` and an optional `clientSecretSuffix`.
- **provider-client-id-public**: `clientId` MUST be treated as not secret, because a desktop client id "appears in every sign-in URL" (the field's comment).
- **provider-secret-suffix**: `clientSecretSuffix` MUST hold only the last `secretSuffixLength` characters of the client secret, and `MailProviderStatus.secretSuffixLength` MUST be 5.
- **provider-secret-never-leaves**: The whole client secret MUST NOT leave the daemon (the field's comment); no field in this file carries it. The one value that carries a secret toward the service is the `json` of `importOAuthClient`.
- **visible-suffix-rule**: `visibleSuffix(ofSecret:)` MUST return the last `secretSuffixLength` characters of the secret only when the secret has at least `secretSuffixLength * 3` characters (15 today), so that at least twice as many characters stay hidden, and nil otherwise.
- **label-record**: `MailLabel` MUST carry Gmail's label `id`, `name`, `type` ("system" or "user"), and optional `parentName`, `messagesTotal` and `messagesUnread`.
- **message-record**: `MailMessage` MUST carry `id` (this system's id), `gmailId`, `threadId`, `account` (the account's email address), `from`, `to`, `cc`, `labels` (Gmail label ids), `labelNames`, `subject`, `snippet`, `date`, `mailClass` (a `MailClass`), optional `bodyText`, optional `bodyHtml` and `attachments` (a list of `EmailAttachmentRef`).
- **message-wire-names**: `to` and `cc` MUST keep those names on the wire; the source's comment calls them "the wire names the RPC contract fixes".
- **message-label-names**: `labelNames` MUST be `labels` mapped to names, falling back to the id (the field's comment).
- **message-snippet**: `snippet` MUST be Gmail's preview text with the HTML entities Gmail leaves in it decoded (the field's comment).
- **message-bodies**: `bodyText` and `bodyHtml` MUST be filled only when bodies are asked for; `bodyText` is the `text/plain` part, or for a message without one its HTML read as text (`HTMLText`), and `bodyHtml` is the `text/html` part as sent.
- **page-record**: `MailMessagePage` MUST carry `messages`, an optional `nextCursor`, `appliedAnyLabels` and `appliedQuery`.
- **page-cursor**: `nextCursor` MUST be opaque, MUST be passed back as the filter's `cursor`, and MUST be nil on the last page.
- **page-applied-flags**: `appliedAnyLabels` MUST be true when the service applied the filter's `anyLabels`, and `appliedQuery` MUST be true when the page is the result of the filter's `query` searched in Gmail.
- **page-decode-lenient**: Decoding a `MailMessagePage` MUST require `messages` only; a missing `nextCursor` is nil and a missing `appliedAnyLabels` or `appliedQuery` is false.
- **thread-record**: `MailThread` MUST carry Gmail's thread `id` and `messages`, oldest message first, and a message carrying `SENT` is one the account wrote.
- **move-result-record**: `MailMoveResult` MUST carry the message's refreshed copy and the names of the labels it gained (`added`) and lost (`removed`), measured against Gmail just before the write; `added` is empty when the message already carried the destination.

### MailResponse

- **response-cases**: `MailResponse` MUST offer exactly these cases: `providerStatus`, `accounts`, `account`, `labels`, `messages`, `message`, `thread`, `moved`, `ok` and `failure`.
- **failure-not-found-flag**: `failure` MUST carry a message and an optional `notFound` flag, defaulting to nil; `notFound` is true when a message id matched nothing.
- **failure-not-found-inside**: The `notFound` flag MUST ride inside `.failure` and MUST NOT be a case of its own, so a client built before it still decodes the reply and shows the message.
- **failure-not-found-factory**: `MailResponse.notFound(_:)` MUST return `.failure(message, notFound: true)`.

### MailClient

- **client-transport**: `MailClient` MUST be a `Sendable` struct built from one injected transport, an async throwing function from request bytes to reply bytes, and MUST NOT depend on a particular transport.
- **client-send-flow**: `send(_:)` MUST encode the request with `JSONEncoder`, call the transport once, and decode the reply as a `MailResponse` with `JSONDecoder`.
- **client-failure-remote**: `send` MUST throw `MailClientError.remote(message)` when the reply is `.failure` and `notFound` is nil or false.
- **client-failure-not-found**: `send` MUST throw `MailClientError.notFound(message)` when the reply is `.failure` and `notFound` is true.
- **client-error-description**: `MailClientError.errorDescription` MUST be the carried message for both cases.
- **client-unexpected**: Each typed method MUST throw `MailClientError.remote("unexpected response from the mail service")` when the reply is a case other than the one it expects.
- **client-typed-methods**: The client MUST offer `providerStatus()` (expects `.providerStatus`), `accounts()` (sends `listAccounts`, expects `.accounts`), `labels(account:)` (expects `.labels`), `messages(_:)` (expects `.messages`), `thread(account:id:includeBodies:)` (expects `.thread`), `message(account:id:)` (expects `.message`), `modifyLabels(account:messageIds:add:remove:)` and `moveMessages(account:messageIds:destination:from:)` (expects `.moved`). The administration requests (`importOAuthClient`, `signIn`, `cancelSignIn`, `removeAccount`, `updateSettings`, `syncNow`, `removeProvider`) have no typed method; a host sends them through `send(_:)` and receives the raw `MailResponse`, whose case depends on the request and is decided by the service ([MailIntegrationService](cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a)).
- **client-thread-include-bodies**: `thread` MUST default `includeBodies` to false.
- **client-modify-labels-reply**: `modifyLabels` MUST expect a `.messages` reply and MUST return that page's `messages`, ignoring the page's other fields.
- **client-move-from-default**: `moveMessages` MUST default `from` to nil.
- **client-query-ignored**: `messages(_:)` MUST throw `MailClient.queryIgnored` when `filter.searchQuery` is not nil and the page's `appliedQuery` is false.
- **client-any-labels-ignored**: `messages(_:)` MUST throw `MailClient.anyLabelsIgnored` when `filter.anyLabels` is not empty and the page's `appliedAnyLabels` is false.
- **client-check-order**: `messages(_:)` MUST run the query check before the any-labels check, so a filter that fails both reports `queryIgnored`.
- **client-threads-unsupported**: `thread` MUST throw `MailClient.threadsUnsupported` when the request fails with `MailClientError.remote(MailClient.badRequest)` (the text `bad request`; `.failure` carries no error code, so the match is on this text), because a service built before threads cannot decode the request; any other error MUST pass through unchanged.
- **client-old-service-messages**: The three older-service messages MUST be `The mail service is too old to filter by any of several labels; restart it and try again.`, `The mail service is too old to search Gmail; restart it and try again.` and `The mail service is too old to show threads; restart it and try again.`, each carried as `MailClientError.remote`.
- **client-bad-request-constant**: `MailClient.badRequest` MUST equal `bad request`, the text `MailIntegrationService` answers to a request it cannot decode.

### Concurrency and Side Effects

- **client-stateless**: `MailClient` MUST hold no state beyond the transport, so any number of calls may run in parallel; ordering between them is whatever the transport and the service give.
- **client-side-effects**: The client MUST have no side effect of its own: no file, no log, no notification and no cache; every call is one transport round trip.
- **client-no-timeout**: The client MUST NOT set a timeout, retry, backoff or cancellation of its own; it relies on the transport's behavior.

### Security

- **sensitive-data**: This contract carries personal mail content (addresses, subjects, snippets, bodies, label names) and, in `importOAuthClient`, the OAuth client JSON that contains the client secret.
- **secret-exposure**: The only form of the client secret the replies carry MUST be `clientSecretSuffix`, produced by `visibleSuffix(ofSecret:)`.
- **transport-security-outside**: This file MUST NOT encrypt, sign or authenticate a request; confidentiality and caller authentication belong to the injected transport and to the service. Token lifetime, storage and revocation for the Gmail account belong to the service and are outside this file.
- **host-gating**: A host that exposes non-UI clients MUST gate them on `isMailboxAccess`, so that administration requests stay with the host's own UI (the property's comment; `MailRequestAccessTests` asserts both sides).

## Appearance

Not applicable — this is a wire contract and a client, not a visual component.

## States

Not applicable — this is a wire contract and a client, not a visual component.

## Accessibility

Not applicable — this is a wire contract and a client, not a visual component.

## Conformance Test Vectors

Tests live in `MailIntegrationServiceTests.swift` and `MailRequestAccessTests.swift`, under `Tests/AgenticDeveloperHubSDKIntegrationsTests`. Vectors with no test name are derived from the source and its comments.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| mail-rpc-001 | mailbox-access-true | `MailRequest.listAccounts`, `.listLabels`, `.listMessages`, `.getMessage`, `.getThread`, `.modifyLabels`, `.moveMessages` (`everyCommandLineRequestIsMailboxAccess`) | each `isMailboxAccess` is true |
| mail-rpc-002 | mailbox-access-false | `.providerStatus`, `.importOAuthClient(json: Data())`, `.removeProvider`, `.signIn`, `.cancelSignIn`, `.removeAccount`, `.updateSettings`, `.syncNow(account: nil)` (`administrationIsNot`) | each `isMailboxAccess` is false |
| mail-rpc-003 | filter-limit-clamp-init, filter-limit-range | `MailMessageFilter(account: "a", limit: 0)` (`messageFilterClampsLimit`) | `limit` is 1 |
| mail-rpc-004 | filter-limit-clamp-init, filter-limit-range | `MailMessageFilter(account: "a", limit: 9_999)` (`messageFilterClampsLimit`) | `limit` is 500 |
| mail-rpc-005 | filter-decode-lenient, filter-limit-range | decode `{"account":"a"}` (`messageFilterClampsLimit`) | equals `MailMessageFilter(account: "a")`, `limit` 50, `includeBodies` false, `anyLabels` empty |
| mail-rpc-006 | filter-limit-clamp-set | build a filter with `limit: 10`, then assign `limit = 600` | `limit` is 500 |
| mail-rpc-007 | filter-decode-clamps | decode `{"account":"a","limit":0}` | `limit` is 1 |
| mail-rpc-008 | filter-decode-lenient | decode `{"limit":5}` with no `account` | decoding throws |
| mail-rpc-009 | filter-search-query | `query` of `" from:sender OR from:other "` | `searchQuery` is `from:sender OR from:other` |
| mail-rpc-010 | filter-search-query | `query` of `"  \n "` and `query` of nil | `searchQuery` is nil in both cases |
| mail-rpc-011 | visible-suffix-rule | `visibleSuffix(ofSecret: "")` (`visibleSuffixKeepsAtLeastTwiceAsMuchHidden`) | nil |
| mail-rpc-012 | visible-suffix-rule | `visibleSuffix(ofSecret: "abcdefghijklmn")`, 14 characters (`visibleSuffixKeepsAtLeastTwiceAsMuchHidden`) | nil |
| mail-rpc-013 | visible-suffix-rule, provider-secret-suffix | `visibleSuffix(ofSecret: "abcdefghij12345")`, 15 characters (`visibleSuffixKeepsAtLeastTwiceAsMuchHidden`) | `"12345"` |
| mail-rpc-014 | failure-not-found-factory, client-failure-not-found, client-error-description | transport replies `MailResponse.notFound("gone")`; call `message(account: "a", id: "m")` (`mailClientThrowsOnFailure`) | throws `MailClientError.notFound("gone")`, whose `localizedDescription` is `gone` |
| mail-rpc-015 | client-failure-remote, client-error-description | the service answers `.failure("No connected account matches “x”")` to `labels(account: "x")` (`mailClientThrowsOnFailure`) | throws `MailClientError.remote("No connected account matches “x”")`; `MailClientError.remote("boom").localizedDescription` is `boom` |
| mail-rpc-016 | failure-not-found-inside | encode `MailResponse.notFound("No message matches “zz”")` and decode it as a type with one case `failure(String)` (`notFoundStillDecodesAsAFailureForAnOlderClient`) | decodes as `.failure` with message `No message matches “zz”` |
| mail-rpc-017 | failure-not-found-flag | decode `{"failure":{"_0":"boom"}}` as `MailResponse` (`notFoundStillDecodesAsAFailureForAnOlderClient`) | equals `.failure("boom")`, so `notFound` is nil |
| mail-rpc-018 | client-any-labels-ignored, page-decode-lenient | transport returns `{"messages":{"_0":{"messages":[]}}}`; call `messages` with `anyLabels: ["INBOX"]` (`aPageFromAServiceThatIgnoredAnyLabelsIsRefused`) | throws `MailClient.anyLabelsIgnored`; the same reply decodes to `MailMessagePage(messages: [], nextCursor: nil)` |
| mail-rpc-019 | client-any-labels-ignored | same reply; call `messages` with no `anyLabels` (`aPageFromAServiceThatIgnoredAnyLabelsIsRefused`) | returns an empty page, no error |
| mail-rpc-020 | client-query-ignored | transport returns `{"messages":{"_0":{"messages":[],"appliedAnyLabels":false}}}`; call `messages` with `query: "from:x"` (`aPageFromAServiceThatIgnoredTheQueryIsRefused`) | throws `MailClient.queryIgnored` |
| mail-rpc-021 | client-check-order | page with both applied flags false; filter with `query: "from:x"` and `anyLabels: ["INBOX"]` | throws `MailClient.queryIgnored`, not `anyLabelsIgnored` |
| mail-rpc-022 | client-threads-unsupported, client-bad-request-constant | transport returns `MailResponse.failure("bad request")`; call `thread(account: "a", id: "t")` (`aThreadFromAServiceThatCantDecodeItSaysTheServiceIsTooOld`) | throws `MailClient.threadsUnsupported` |
| mail-rpc-023 | client-threads-unsupported | transport returns `MailResponse.failure("boom")`; call `thread` | throws `MailClientError.remote("boom")` unchanged |
| mail-rpc-024 | client-unexpected | transport returns `MailResponse.ok`; call `accounts()` | throws `MailClientError.remote("unexpected response from the mail service")` |
| mail-rpc-025 | client-modify-labels-reply | transport returns `.messages` with two messages for `modifyLabels` | returns those two messages |
| mail-rpc-026 | client-modify-labels-reply, client-unexpected | transport returns `.ok` for `modifyLabels` | throws the unexpected-response error |
| mail-rpc-027 | client-typed-methods, client-send-flow | in-process service answers `listAccounts` and `providerStatus` (`mailClientThrowsOnFailure`) | `accounts()` is `[]`; `providerStatus()` equals `MailProviderStatus(configured: false, clientId: nil)` |
| mail-rpc-028 | client-send-flow | the service handles `Data("nope".utf8)` (`undecodableRequestIsBadRequest`) | the reply decodes to `.failure("bad request")` |
| mail-rpc-029 | client-transport, client-send-flow | transport throws its own error | `send` rethrows the same error |
| mail-rpc-030 | page-applied-flags, filter-any-labels-or | service lists with `anyLabels: ["INBOX"]` and again with `labels` only (`MailIntegrationServiceTests`, the any-labels listing test) | first page has `appliedAnyLabels` true; second has it false |
| mail-rpc-031 | filter-any-labels-or | service lists with `anyLabels: ["INBOX", "Nope"]` | the reply is `.failure("unknown label: Nope")`; the refusal of an unknown label is the service's behavior and no requirement in this recipe covers it |
| mail-rpc-032 | filter-query-gmail, page-applied-flags | service lists with `query: " from:sender OR from:other "`, `labels: ["Work"]`, `limit: 2` | first page has `appliedQuery` true |
| mail-rpc-033 | request-wire-form | encode `MailRequest.listAccounts` and hand the bytes to the service's `handle(requestData:)` (`requestRoundTripsThroughData`) | the reply decodes as `MailResponse.accounts([])`, so the service decoded the request |
| mail-rpc-034 | response-cases, failure-not-found-factory | `MailResponse.notFound("x")` | equals `.failure("x", notFound: true)` |
| mail-rpc-035 | mailbox-access-exhaustive | static check, not a runnable vector: review that `isMailboxAccess` is a `switch` with no `default`; adding a `MailRequest` case with no entry makes the module fail to compile | the module fails to compile |

## Edge Cases

- **Empty and missing data**: `MailMessageFilter` decoding MUST accept `{"account":"a"}`; every other field takes its default. A missing `account` MUST fail decoding.
- **Empty collections**: `modifyLabels` and `moveMessages` MUST send empty `messageIds`, `add`, `remove` and `from` as given; this file does not reject them, and the service decides what an empty list means (an empty `from` removes nothing, per the case's comment).
- **Whitespace-only query**: A `query` that trims to nothing MUST count as no query, so no search runs and `queryIgnored` cannot be raised.
- **Boundary limits**: `limit` of 0 or less MUST become 1; `limit` above 500 MUST become 500; 1 and 500 MUST pass unchanged.
- **Cursor on the last page**: `nextCursor` MUST be nil on the last page, which ends paging.
- **Short secret**: A client secret under 15 characters MUST show no suffix, so `clientSecretSuffix` is nil.
- **Older service, any-of labels**: A page without `appliedAnyLabels` decodes as false and MUST be refused when `anyLabels` was sent, because the older service listed everything.
- **Older service, query**: A page without `appliedQuery` decodes as false and MUST be refused when a query was sent, because the older service listed the synced copy.
- **Older service, threads**: An older service cannot decode `getThread` and answers `bad request`; the client MUST report that as a service too old to show threads. The same text from any other request is not translated.
- **Older client, not found**: A client built before `notFound` MUST still decode a not-found reply as a plain failure and show its message.
- **Wrong reply shape**: A reply of a case the method did not expect MUST throw the `unexpected response` error, not return a default value.
- **Malformed reply bytes**: The decoder's own error propagates from `send`, unwrapped; this file adds no error type for it.
- **Transport failure**: An error thrown by the transport (an unreachable daemon, a broken connection) propagates from `send` unchanged; the client does not retry.
- **Concurrent calls**: Not a hazard in this file: `MailClient` is stateless and `Sendable`, so parallel calls share nothing; interleaving is the service's concern.
- **Cancellation and timeout**: The client has no cancellation or timeout logic of its own; a cancelled task behaves as the transport does.
- **Offline or unreachable service**: Surfaces as the transport's thrown error; there is no cached or degraded answer.
- **Idempotency**: Each call sends one request with no idempotency key; whether a repeated `modifyLabels`, `moveMessages` or `syncNow` is safe is decided by the service, not by this file.
- **Unvalidated dates**: `since` and `until` pass through as text; the command-line and MCP front ends validate them before building a filter (see the [MailCommandSupport](cookbook:3d12c073-edc3-44fb-a988-5edec20575e0) recipe).

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `transport` | `@Sendable (Data) async throws -> Data` | none, required | Sends request bytes to a `MailIntegrationService` and returns the reply bytes; XPC, a socket or an in-process call. |
| `MailMessageFilter.limitRange` | `ClosedRange<Int>` | `1...500` | Bounds that `limit` is clamped to. |
| `MailMessageFilter.defaultLimit` | `Int` | `50` | The `limit` when none is given or decoded. |
| `MailProviderStatus.secretSuffixLength` | `Int` | `5` | How many trailing characters of the client secret may be shown. |
| `includeBodies` (filter, `getThread`) | `Bool` | `false` | Whether messages carry `bodyText` and `bodyHtml`. |
| `from` (`moveMessages`) | `[String]?` | `nil` | Labels to remove; nil means INBOX, or nothing when the destination is INBOX. |

There are no environment variables or settings keys.

## Deep Linking

Not applicable: the file exposes no URL or navigation entry point; it defines request and reply types and a client.

## Localization

The file holds user-facing English strings that are not localized: the three older-service messages, `unexpected response from the mail service`, and the `errorDescription` of `MailClientError`, which returns whatever message the service sent. The service's own failure messages (for example `Sign-in was cancelled`) are written outside this file. There is no string table or locale handling, and the source marks no string for translation.

## Accessibility Options

Not applicable: the file has no visual output, motion or colour, so no display option applies.

## Feature Flags

Not applicable: the source reads no flag or setting; the only version signal is the `appliedAnyLabels` and `appliedQuery` fields on a page.

## Analytics

Not applicable: the source emits no events.

## Privacy

- **Data collected**: None by this file. The records carry the mail the service already holds: addresses (`from`, `to`, `cc`, `account`), subjects, snippets, bodies and label names.
- **Storage**: None. `MailClient` keeps nothing; it holds only the transport.
- **Transmission**: Requests and replies leave the process over whatever transport is injected; this file adds no encryption or authentication. The full OAuth client secret travels toward the service inside the `json` of `importOAuthClient`, and no reply carries it; replies carry at most the last 5 characters.
- **Retention**: None in this file.

## Logging

Not applicable: the source makes no log call; failures are thrown or returned.

## Platform Notes

- **SwiftUI**: Source platform is Swift: `packages/apple/AgenticDeveloperHubSDK/Integrations/Service/MailRPC.swift`. It uses `Foundation` only: synthesized `Codable` for the enums (which gives the `_0` payload keys seen in the tests), `JSONEncoder` and `JSONDecoder` with default settings, `LocalizedError` on `MailClientError`, and a `@Sendable` async closure as the transport. Tests live in `Tests/AgenticDeveloperHubSDKIntegrationsTests`. A SwiftUI host holds a `MailClient` and awaits its methods from tasks.
- **Compose**: Model `MailRequest` and `MailResponse` as sealed interfaces with `kotlinx.serialization`, and give each case a serializer that writes the same `_0` payload key (a custom serializer, since Kotlin's default class discriminator differs). Use `Int.coerceIn(1, 500)` for the limit, default values for the lenient decode, and `ignoreUnknownKeys = true` so a new field does not break an older client. The transport becomes a `suspend (ByteArray) -> ByteArray`; `MailClientError` is a sealed `Exception` pair, and the page-flag checks run exactly as in `messages(_:)`.
- **React/Web**: Use TypeScript discriminated unions for the two enums, writing the wire form by hand to keep the `_0` keys, and `fetch` or a socket as the transport (`(bytes: Uint8Array) => Promise<Uint8Array>`). Missing booleans must be read as false (`page.appliedQuery ?? false`) so the older-service checks still fire. `Math.min(Math.max(limit, 1), 500)` replaces the clamp; there is no property observer, so clamp in a setter or a factory. Throw `Error` subclasses for `remote` and `notFound`.
- **AppKit / UIKit**: The source is `Foundation` only, and this recipe lists `swift` and `macos`; an iOS build is planned. An AppKit or UIKit host calls the client from an async task and shows `errorDescription` in an alert or label; it gates any non-UI client on `isMailboxAccess` and keeps administration requests behind its own settings panel.
- **WinUI 3**: Port to C# records with `System.Text.Json`. Model each enum as an abstract record with one derived record per case and a custom `JsonConverter` that writes the case name as the single key and the payload under `_0`; mark optional fields nullable and give `MailMessagePage.AppliedAnyLabels` and `AppliedQuery` a default of false so a missing key reads as false. Use `Math.Clamp(limit, 1, 500)` in the constructor and in the property setter. The transport is a `Func<byte[], CancellationToken, Task<byte[]>>` (named pipe, `Windows.Networking.Sockets`, or an in-process call), and `MailClient` is a sealed class with `async Task<T>` methods that throw `MailClientException` carrying a `NotFound` flag. Keep results as immutable records; there is no `INotifyPropertyChanged` need, since the types are wire data, and a view model that wants binding wraps them in an `ObservableCollection` of its own. Add a `CancellationToken` parameter, which the Swift source lacks, but keep the same refusals and messages.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |
| apple | `packages/apple/AgenticDeveloperHubSDK/Integrations/Service/MailRPC.swift` | unverified |

## Design Decisions

**Decision**: `notFound` rides inside `.failure` as an optional flag instead of being its own `MailResponse` case.
**Rationale**: The type's comment says a client built before the flag still decodes the reply and shows the message; a new case would make an older client fail to decode it.
**Approved**: pending

**Decision**: The page carries `appliedAnyLabels` and `appliedQuery`, and `MailClient.messages` throws when a flag the request needed is false.
**Rationale**: An older service decodes the filter without the new fields and lists everything; its reply omits the flags, which decode as false, so the client can tell the filter was ignored and refuses a wrong answer rather than showing it.
**Approved**: pending

**Decision**: The client turns the text `bad request` from `getThread` into "too old to show threads".
**Rationale**: A service built before threads cannot decode the request and answers `bad request`; the client is the only place that knows which request was sent. The match is on the exact text, so a different failure is passed through.
**Approved**: pending

**Decision**: `MailMessageFilter` decodes leniently, with only `account` required, and clamps `limit` both in the initializer and in a `didSet`.
**Rationale**: A caller or tool can send a short filter, and a limit outside 1 through 500 can never reach the service. A `didSet` does not run inside an initializer, so the initializer clamps on its own.
**Approved**: pending

**Decision**: `isMailboxAccess` is an exhaustive switch with no default.
**Rationale**: A host gates its non-UI clients on this flag, so a new request must be placed on one side before the code compiles.
**Approved**: pending

**Decision**: `clientSecretSuffix` shows the last 5 characters only when at least 15 characters exist.
**Rationale**: The user can tell which secret is stored, while at least twice as many characters stay hidden; a short secret shows nothing.
**Approved**: pending

**Decision**: The older-service error messages end with "restart it and try again".
**Rationale**: The source words them that way for a service that predates a field; the likely cause is a daemon still running from before an upgrade.
**Approved**: pending

**Decision**: The client sets no timeout, retry or cancellation, and signs no request.
**Rationale**: The transport is injected and may be XPC, a socket or in-process, so these concerns stay with the transport; the source leaves them out, and this ingredient records that as the contract.
**Approved**: pending

**Decision**: `since` and `until` are plain `String` values, not `Date`.
**Rationale**: The filter is wire data that an older service must still decode, and the front ends (`MailCommandLine`, `MailToolSource`) validate the text before building a filter (see the `MailCommandSupport` recipe); the service owns parsing it. The ISO-8601 form is therefore a documented convention, not something this file enforces.
**Approved**: pending

**Decision**: `.failure` carries no error code, so the client recognizes an old service by the text `bad request`, held in `MailClient.badRequest`.
**Rationale**: Adding a code would be another field an older service does not send. The client and `MailIntegrationService` agree on the text by convention; no test ties `MailClient.badRequest` to the service's own constant, and vector 028 shows the service answering that text.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | passed | access-patterns |
| [adc.check.access-patterns.pagination-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/e29ce31a-67cb-5690-b2ca-b1065ccdaf1a) | passed | access-patterns |
| [adc.check.access-patterns.timeout-configuration](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dc15eb62-a72c-5b09-b9e7-c1bed983f499) | failed | access-patterns |
| [adc.check.access-patterns.retry-with-backoff](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bcb17bfe-d2d6-53f3-b2af-06b7eea3da61) | failed | access-patterns |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | privacy-and-data |
| [adc.check.security.secure-transport](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0a75f61f-9508-506e-b92e-0f5b29a91c95) | partial | security |

The file separates the wire contract and a one-round-trip client from the service that answers it, so separation of concerns passes. `MailIntegrationServiceTests` and `MailRequestAccessTests` assert the clamp, the lenient decode, the secret suffix rule, the not-found paths, the three older-service refusals and the `isMailboxAccess` split, but vectors 006 to 010, 021, 023 to 026, 029 and 034 are derived from the source and have no named test, so unit-test coverage is partial. Failures are thrown as `MailClientError` with the service's message, and a reply of the wrong shape is an explicit error, so error handling and error-response handling pass. Paging uses an opaque `nextCursor`, so pagination passes. The client sets no timeout and no retry, which are left to the transport on purpose (see the Design Decision on timeout, retry and cancellation), so those two checks fail for this file; a caller needing them adds them in the transport, not in the client. The secret is reduced to a short suffix before it leaves the daemon, which meets data minimization. The file neither encrypts nor authenticates a request and leaves that to the injected transport, so secure transport is partial.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
