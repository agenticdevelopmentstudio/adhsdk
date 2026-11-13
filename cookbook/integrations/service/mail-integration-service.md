---
id: aed9acc9-6340-487b-acfb-b7b13f14e59a
title: "Mail Integration Service"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-13
modified: 2026-11-13
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Actor that answers MailRequests for Gmail, signs accounts in, polls and syncs them, and writes label changes back to Gmail."
platforms:
  - swift
  - macos
tags:
  - gmail
  - mail-service
  - integrations
depends-on:
  - 1157bca1-0d27-49e9-a989-d637505ba5f1
  - c19280fd-b80c-46f3-a6a7-0b60a0c90d91
  - c448c9f4-195d-4625-a49d-22dd5468a914
  - fc9671be-170c-436e-9628-892624952191
related:
  - fafeef0d-c283-4ecf-92fb-b5de35d71f79
references: []
approved-by: ""
approved-date: ""
---

# Mail Integration Service

## Overview

`MailIntegrationService` is the host-agnostic Gmail service a daemon hosts. It is a Swift `actor` that answers `MailRequest` values with `MailResponse` values, runs a poll scheduler that syncs each connected Gmail account on its own interval, signs accounts in through a browser OAuth flow, and writes label changes (modify and move) back to Gmail. It does not talk to Gmail or Google directly: it composes an `IntegrationsStore`, a `SecretStoring` Keychain wrapper, a `GoogleSignInFlow`, a `GoogleTokenEndpoint`, a `GoogleTokenProvider`, a `GmailAPI` factory and `GmailSyncWorker`; all but the worker are injected or derived in `init`, and each sync builds its own worker.

Use it as the single owner of Gmail state in a process. Per-connection sync serialisation, status recording (`active`, `error`, `revoked`), the sign-in slot, the provider-removal fence and the paging cursors all live here, so the sync worker, the REST client and the UI stay free of them. The contract is also carried over a JSON transport: `handle(requestData:)` takes encoded request bytes and returns encoded response bytes.

## Behavioral Requirements

Contract: `public actor MailIntegrationService` with `public init(store:secrets:signIn:tokenEndpoint:makeAPI:now:)`, `public func handle(_ request: MailRequest) async -> MailResponse`, `public nonisolated func handle(requestData: Data) async -> Data`, `public func start(tick: Duration = .seconds(60))`, `public func stop(timeout: Duration = .seconds(5)) async` and `public func runDueSyncs() async`. Internal members (`runningSyncCount`, `schedulerTask`, `setObserver`, `waitForIdle`, `MailServiceEvent`) exist for tests. Mutable state is `running` (one `RunningSync` per connection id), `scheduler`, `observer`, `lastAttempt`, `removing`, `pendingSignIn`, `providerGeneration` and `providerRemovals`.

### Isolation and construction

- **actor-isolation**: The service MUST be an actor so that every read and write of its mutable state is serialised; the only nonisolated member MUST be `handle(requestData:)`, which hops into the actor by calling `handle(_:)`.
- **injected-dependencies**: `init` MUST accept the store, the secret store, a sign-in flow (default `AppAuthGoogleSignIn()`), a token endpoint (default `URLSessionGoogleTokenEndpoint()`), a Gmail API factory (default builds `GmailRESTClient`) and a clock (default `Date.init`).
- **token-provider-shared-clock**: `init` MUST build its `GoogleTokenProvider` from the same secret store, token endpoint and clock it was given.
- **provider-constants**: The provider id MUST be `gmail` and the requested OAuth scopes MUST be `openid email https://www.googleapis.com/auth/gmail.modify`.

### Request handling

- **handle-never-throws**: `handle(_:)` MUST NOT throw; every error raised while dispatching MUST be returned as a `MailResponse`.
- **error-to-failure**: Any error other than an unknown message MUST become `.failure` carrying the error's `localizedDescription`.
- **unknown-message-not-found**: An `IntegrationError.unknownMessage` MUST become `MailResponse.notFound(...)` with that error's `localizedDescription`, which is `.failure` with `notFound: true`.
- **request-data-decoding**: `handle(requestData:)` MUST decode the bytes as a `MailRequest` with `JSONDecoder`, call `handle(_:)` and return the response encoded with `JSONEncoder`.
- **bad-request**: `handle(requestData:)` MUST answer `.failure("bad request")` (the value of `MailClient.badRequest`) when the bytes do not decode as a `MailRequest`.
- **encoding-fallback**: When the response cannot be encoded, `handle(requestData:)` MUST return the literal bytes of `{"failure":{"_0":"encoding failed"}}`.
- **dispatch-providerStatus**: `.providerStatus` MUST answer `.providerStatus` with the current provider status.
- **dispatch-importOAuthClient**: `.importOAuthClient(json:)` MUST answer `.providerStatus` with the status after the import.
- **dispatch-removeProvider**: `.removeProvider` MUST answer `.ok` after the provider has been removed.
- **dispatch-listAccounts**: `.listAccounts` MUST answer `.accounts` with one `MailAccount` per stored `gmail` connection, in store order.
- **dispatch-signIn**: `.signIn` MUST answer `.account` with the signed-in account.
- **dispatch-cancelSignIn**: `.cancelSignIn` MUST cancel the pending sign-in task if there is one and MUST answer `.ok` whether or not one was pending.
- **dispatch-removeAccount**: `.removeAccount(account:)` MUST resolve the account argument, remove the account and answer `.ok`.
- **dispatch-updateSettings**: `.updateSettings(account:settings:)` MUST answer `.account` with the account after the change.
- **dispatch-syncNow**: `.syncNow(account:)` MUST answer `.accounts` with the synced targets re-read after their syncs end.
- **dispatch-listLabels**: `.listLabels(account:)` MUST answer `.labels` from the stored labels of the resolved connection, without calling Gmail.
- **dispatch-listMessages**: `.listMessages(filter)` MUST answer `.messages` with a `MailMessagePage`.
- **dispatch-getMessage**: `.getMessage(account:id:)` MUST answer `.message` with bodies included (`includeBodies: true`).
- **dispatch-getThread**: `.getThread(account:id:includeBodies:)` MUST answer `.thread`.
- **dispatch-modifyLabels**: `.modifyLabels(account:messageIds:add:remove:)` MUST answer `.messages` with a `MailMessagePage` whose `nextCursor` is nil.
- **dispatch-moveMessages**: `.moveMessages(account:messageIds:destination:from:)` MUST answer `.moved` with a list of `MailMoveResult`.
- **account-resolution**: An account argument MUST resolve to the `gmail` connection whose `id` equals it exactly, else the one whose `externalAccountId` equals its lowercased form, else fail with `IntegrationError.unknownAccount`.

### Provider

- **status-unconfigured**: `providerStatus` MUST report `configured: false` and a nil `clientId` when the provider config row or the Keychain client secret is missing.
- **status-configured**: `providerStatus` MUST report `configured: true`, the stored `clientId` and `clientSecretSuffix` from `MailProviderStatus.visibleSuffix(ofSecret:)` when both exist.
- **secret-suffix-rule**: `visibleSuffix(ofSecret:)` MUST return the last 5 characters (`secretSuffixLength`) of the secret only when the secret has at least 15 characters (three times that length), else nil.
- **secret-never-leaves**: A response MUST NOT contain the client secret beyond that suffix.
- **import-parses-json**: Importing an OAuth client MUST parse the JSON with `GoogleOAuthClientConfig.parse(json:)` and surface its parse error when the JSON is not a valid client.
- **import-saves-secret-first**: Importing MUST write the client secret to the secret store under `GoogleTokenProvider.clientSecretKey` before it writes the provider config row.
- **import-keychain-failure**: When the secret store refuses the write, the import MUST fail with `Could not save the OAuth client secret to the Keychain` and MUST NOT write the provider config.
- **import-provider-row**: Importing MUST upsert a `ProviderConfig` with a new lowercase UUID id, provider id `gmail`, name `Gmail` and the parsed `clientId`.
- **keychain-read-failure**: A secret store read that throws MUST surface as `IntegrationError.keychain` with the text `Could not read the OAuth client secret: ` followed by the cause, and MUST NOT be treated as "not configured".
- **oauth-config-required**: Any operation that needs the OAuth client MUST fail with `IntegrationError.notConfigured` when the provider config or its secret is absent.
- **remove-provider-fence**: `removeProvider` MUST increment `providerGeneration` and `providerRemovals`, and MUST decrement `providerRemovals` when it ends, however it ends.
- **remove-provider-cancels-sign-in**: `removeProvider` MUST cancel and clear the pending sign-in.
- **remove-provider-accounts**: `removeProvider` MUST remove every `gmail` connection, then delete the provider config row, then delete the client secret from the secret store.

### Sign-in

- **sign-in-blocked-during-removal**: `signIn` MUST fail with `IntegrationError.notConfigured` while `providerRemovals` is not zero.
- **sign-in-supersedes**: A new sign-in MUST cancel any sign-in still pending and take the single `pendingSignIn` slot, so only the newest browser flow can add an account.
- **sign-in-slot-ownership**: When a sign-in ends, it MUST clear `pendingSignIn` only if the slot still holds its own task.
- **sign-in-cancelled**: A sign-in whose task is cancelled, or that throws `CancellationError`, MUST fail with `IntegrationError.signInCancelled`; any other flow error MUST propagate unchanged.
- **sign-in-email-key**: The account identity MUST be the lowercased `emailAddress` returned by the Gmail profile call made with the new access token.
- **sign-in-reuses-account**: When a connection with that email already exists, sign-in MUST reuse its id; otherwise it MUST use a new lowercase UUID.
- **sign-in-credential-first**: Sign-in MUST store the credential through `GoogleTokenProvider.store(_:connectionId:)` before it upserts the connection, so a failed Keychain write leaves no active connection without a credential.
- **sign-in-connection-fields**: Sign-in MUST upsert the connection with status `.active`, `displayName` equal to the email, nil `lastError`, `scopes` equal to the service scopes, and `lastSyncAt`, `syncCursor` and `syncSettings` carried over from an existing connection (defaulting settings to `MailSyncSettings.default`).
- **sign-in-rereads-state**: Sign-in MUST re-read the existing connection after the credential save, so sync state written meanwhile is not rolled back.
- **sign-in-provider-removed**: When `providerGeneration` changed during sign-in, sign-in MUST fail with `signInCancelled` and MUST revoke what it obtained: the raw credential before it is stored, or the stored credential (revoked then forgotten) after.
- **sign-in-profile-failure-no-revoke**: When the Gmail profile call fails after Google issued a grant, sign-in MUST fail with that error, MUST create no connection and MUST NOT revoke the grant at Google; only `sign-in-provider-removed` and the removal paths revoke it.
- **sign-in-starts-sync**: A successful sign-in MUST start a sync for the account without awaiting it and MUST answer with the account read back from the store.
- **discarded-revoke-logged**: Revoking a never-stored credential MUST be best effort, and a failure MUST be logged at error level and not thrown.

### Account removal and settings

- **remove-account-order**: `removeAccount` MUST stop the account's sync and wait for it, revoke the grant at Google, forget the credential, delete the connection, and clear its `lastAttempt` entry, in that order.
- **remove-account-dedupe**: A removal of an account already being removed MUST return at once without a second removal.
- **remove-account-no-sync**: A sync MUST NOT start for an account while its removal runs.
- **remove-account-revoke-best-effort**: A failure to revoke at Google MUST NOT fail the removal.
- **remove-account-keychain-failure**: A credential the secret store will not remove MUST fail the removal and leave the connection in place.
- **settings-validated**: `updateSettings` MUST validate the settings first and fail with `IntegrationError.invalidSettings` unless `windowDays` is in 1...3650 and `pollIntervalMinutes` is in 1...1440.
- **settings-unchanged**: When the new settings equal the stored ones, `updateSettings` MUST return the current account without stopping or starting a sync.
- **settings-quiesce**: Otherwise `updateSettings` MUST cancel and await the account's running sync before it changes anything.
- **settings-tombstone-classes**: `updateSettings` MUST tombstone stored messages of each `MailClass` the old settings allowed and the new ones do not.
- **settings-tombstone-window**: When `windowDays` shrinks, `updateSettings` MUST tombstone messages older than now minus `windowDays` times 86,400 seconds immediately.
- **settings-widen-clears-cursor**: When a class becomes allowed or `windowDays` grows, `updateSettings` MUST set the connection's `syncCursor` to nil so the next sync is a full one.
- **settings-resync**: After saving, `updateSettings` MUST start a sync for the account when its status is `active` or `error`, and MUST NOT start one when it is `revoked`.

### Scheduler

- **start-loop**: `start(tick:)` MUST cancel any previous loop and start one that, per iteration, starts every due sync, notifies the observer with `.schedulerTick`, then sleeps `tick` (default 60 seconds).
- **loop-weak-self**: The loop MUST hold the service weakly per iteration and end when the service is gone.
- **stop-cancels**: `stop(timeout:)` MUST cancel the loop and clear it, and cancel every running sync.
- **stop-bounded-wait**: `stop(timeout:)` MUST wait for the cancelled syncs to end for at most `timeout` (default 5 seconds), so a sync stuck in a call that ignores cancellation cannot hold up shutdown.
- **run-due-syncs**: `runDueSyncs()` MUST start every due sync and wait for all of them.
- **syncable-status**: A connection MUST be syncable only when its status is `active` or `error`.
- **due-rule**: A connection MUST be due when it is syncable, not being removed, and a poll interval (`pollIntervalMinutes` times 60 seconds) has passed since the later of its `lastSyncAt` and its in-memory last attempt, or when neither exists.
- **due-malformed-last-sync**: A missing or unparseable `lastSyncAt` (ISO 8601 with fractional seconds) MUST count as never synced.
- **last-attempt-memory**: The last attempt time MUST be recorded when a sync task begins and finds its connection in the store, successful or not (a sync for a vanished connection records none), and MUST be kept in memory only, so after a restart due-ness falls back to `lastSyncAt`.
- **one-sync-per-connection**: At most one sync MUST run for a connection id; a request to start another, or to start one for a connection being removed, MUST return no task.
- **sync-token-guard**: A finishing sync MUST clear its `running` entry only when the entry still carries its own token.
- **sync-skips-vanished**: A sync for a connection id the store no longer has MUST end silently without writing.
- **sync-outcome-ignored**: The service MUST discard the `GmailSyncWorker.sync` outcome; success is recorded by the worker itself.
- **record-cancellation**: A sync that fails by cancellation MUST record nothing.
- **record-revoked**: A sync that fails with `IntegrationError.revoked` MUST set the connection status to `revoked`.
- **record-error**: Any other sync failure MUST set status `error` with the error's `localizedDescription` as `lastError`, preserving the stored cursor and `lastSyncAt`.
- **status-write-errors**: The status write in `record` MUST swallow a store failure: a failure while recording `error` or `revoked` is neither logged nor signalled (see the Design Decision on swallowed store failures).
- **scheduler-store-read**: `startDueSyncs` MUST start nothing when reading connections fails, without a log or signal (see the Design Decision on swallowed store failures).
- **sync-now-targets**: `syncNow(account:)` MUST target the named account, or every syncable `gmail` connection when `account` is nil.
- **sync-now-bypasses-due**: `syncNow` MUST start syncs regardless of due-ness.
- **sync-now-joins**: When a sync is already running for a target, `syncNow` MUST notify the observer with `.joinedRunningSync(id)` and wait for that sync rather than start another.
- **sync-now-not-syncable**: `syncNow` for a named account MUST fail with `IntegrationError.revoked` when its status is `revoked`, and with `account <email> is not ready to sync` for any other non-syncable status.
- **sync-now-failures-in-status**: A sync that fails inside `syncNow` MUST NOT fail the request; the failure appears as the account's `status` and `lastError` in the returned accounts.

### Listing messages

- **list-source**: Without a `query`, `listMessages` MUST read from the local mirror (`store.messages`), not from Gmail.
- **limit-clamp**: The limit MUST be clamped to 1...500 (`MailMessageFilter.limitRange`), with a default of 50 and `includeBodies` defaulting to false.
- **page-extra-row**: The mirror query MUST ask for `limit + 1` rows; the page MUST hold at most `limit` messages and carry a `nextCursor` only when the extra row exists.
- **cursor-keyset**: A mirror cursor MUST be the text `<internalDate>|<id>` of the last returned row, and the next page MUST start after that key, never after a row count.
- **cursor-invalid**: A mirror cursor that does not split at the first `|` into two non-empty parts MUST fail with `invalid cursor: <cursor>`.
- **labels-all-of**: `filter.labels` MUST narrow the result to messages carrying all of the named labels, and `filter.anyLabels` to messages carrying at least one.
- **applied-any-labels**: The page MUST set `appliedAnyLabels` to true exactly when any-label ids were resolved, so a client can detect a service that ignored them.
- **label-resolution**: A label value MUST resolve to a Gmail label id by exact id first, then by exact case-sensitive name; duplicates MUST be dropped; any other value MUST fail with `unknown label: <value>`.
- **label-refresh**: When a value matches no stored label, the service MUST re-read the labels from Gmail and store them before resolving, and MUST fail with `account <email> was removed` instead of storing when the account vanished during the read.
- **message-mapping**: A `MailMessage` MUST carry the Gmail id, thread id, account email, from, to, cc, label ids, label names (the id when a name is unknown), subject, snippet with HTML entities decoded, `internalDate` as `date`, mail class and attachments; bodies only when requested.
- **body-text-fallback**: `bodyText` MUST be the `text/plain` part unless it is missing or blank after trimming whitespace, in which case it MUST be the HTML part converted to plain text, falling back to the original text when the conversion is empty.
- **since-until-unvalidated**: A mirror listing MUST pass `since` and `until` to the store as given, without checking that they are ISO 8601 timestamps; only a search validates them (`search-bound-invalid`).

### Searching Gmail

- **search-trigger**: A non-nil `filter.searchQuery` (the `query` field; blank text is nil) MUST switch `listMessages` to a Gmail search.
- **search-any-label-refused**: A search MUST fail with `a query can't be combined with any-label; write {label:a label:b} in the query` when `anyLabels` is not empty.
- **search-cursor-prefix**: A search cursor MUST be `gmail:` followed by Gmail's page token, and a cursor without that prefix, or with nothing after it, MUST fail with `invalid cursor: <cursor>`.
- **search-bounds**: `since` and `until` MUST be added to the query as `after:<epoch seconds>` and `before:<epoch seconds + 1>`, rounded down, and the original query MUST be wrapped in parentheses when any bound is added.
- **search-no-bounds**: With no bounds the query MUST be sent exactly as written.
- **search-bound-invalid**: A bound that is not ISO 8601 (with or without fractional seconds) MUST fail with `invalid since: <text>` or `invalid until: <text>`.
- **search-order**: Results MUST keep Gmail's order (newest first), omitting a message Gmail no longer has.
- **search-not-stored**: A search MUST NOT write the found messages to the mirror, but MUST reuse an existing local id when the message was ever stored.
- **search-revoked**: A revoked error during a search or any other Gmail read MUST be recorded on the connection before it is rethrown.

### Getting a message or thread

- **resolve-messages**: A message id (ours or Gmail's) MUST resolve to a live mirror row, else be read from Gmail using the tombstoned row's Gmail id when the id is ours.
- **resolve-order**: Resolved messages MUST keep the order of the requested ids.
- **resolve-not-found**: A Gmail 400 or 404 while resolving an id MUST fail with `IntegrationError.unknownMessage`, so the response is `notFound`.
- **resolve-not-stored**: A message read from Gmail to resolve an id MUST NOT be stored.
- **thread-known-message**: For an id naming a message the mirror knows, live or tombstoned, `getThread` MUST read the thread of that message's `threadId` from Gmail.
- **thread-unknown-id**: For any other id, `getThread` MUST try it as a Gmail thread id, then as a Gmail message id whose thread is read; a 400 or 404 from both MUST fail with `unknownMessage`.
- **thread-gone**: A 404 on the thread of a known message MUST fail with `unknownMessage`.
- **thread-not-stored**: A thread MUST NOT be stored; each message MUST be parsed with the local id when one exists.

### Writing labels

- **modify-resolves-first**: `modifyLabels` MUST resolve every label and message id before it calls Gmail, so an unknown label or message fails with no write.
- **modify-noop**: `modifyLabels` MUST return the resolved messages unchanged, without a write, when both `add` and `remove` resolve to no ids or no message resolved.
- **modify-payload**: `modifyLabels` MUST write the resolved Gmail ids, the add ids and the remove ids through `batchModify`.
- **batch-chunking**: A label write MUST be sent in chunks of `GmailRESTClient.batchModifyLimit` Gmail ids (1,000), in request order.
- **write-action-log**: A label write MUST insert an action log row (type `modify_labels` or `move_messages`, with the JSON payload) before calling Gmail, and finish it with status `error` and the applied count if Gmail fails, or status `ok` with `modified` when the write succeeds.
- **write-failure-rethrown**: A Gmail failure during the write MUST be rethrown to the caller after the log is finished, and a revoked failure MUST also be recorded on the connection.
- **write-refetch**: After a successful write, the service MUST re-read the written messages from Gmail and store them.
- **refetch-failure**: When the re-read or store fails after the write, the service MUST finish the log as `ok` with `refreshError`, and MUST fail with `labels applied; refreshing messages failed: <message>`.
- **refetch-concurrency**: Re-reads MUST run at most 8 at a time (`refetchConcurrency`), keyed by position, and a message Gmail answers with 404 MUST be absent from the result.
- **store-refetched**: Re-read messages MUST be checked against the connection's current settings: those whose class is no longer allowed, and those Gmail no longer has, MUST be tombstoned, the rest upserted, and an account removed meanwhile MUST get no writes.
- **move-resolves-labels**: `moveMessages` MUST resolve the destination and `from` labels (refreshing from Gmail when a name is unknown) before it reads any message.
- **move-default-sources**: When `from` is nil, the sources MUST be `INBOX`, except that a move into `INBOX` has no sources; an empty `from` removes nothing.
- **move-conflict**: A destination that is also among the resolved `from` ids MUST fail with `cannot move to <destination>: it is also a label to move from`.
- **move-empty**: A move whose messages resolve to none MUST return an empty result.
- **move-reads-gmail-first**: `moveMessages` MUST read each message from Gmail before it writes, and MUST compute `added` and `removed` from that read, never from the local copy.
- **move-skips-unchanged**: A message that already has the destination and none of the `from` labels MUST NOT be written, and MUST be stored as just read.
- **move-single-write**: The changing messages MUST be written together: add the destination, remove every `from` id, in one `move_messages` write.
- **move-result**: Each `MailMoveResult` MUST carry the message, `added` (the destination name, or empty when it already had it) and `removed` (only the `from` labels it carried), using label names where known; a message Gmail no longer has MUST be left out.

### Concurrency and ordering

- **sync-serialised-per-connection**: Syncs MUST be serialised per connection (see one-sync-per-connection) and MAY run in parallel across connections.
- **quiesce-loop**: Stopping one connection's sync MUST cancel it and await it, repeating until the `running` entry is gone.
- **suspension-rechecks**: After any await that precedes a write to the store, the service MUST re-read the connection or provider generation it depends on, not rely on a snapshot taken before the await.
- **fetch-tasks-parallel**: Message re-reads MAY run in parallel up to 8; every other operation within one request MUST run sequentially.

### Persistence and side effects

- **writes-to-store**: The service MUST write to `IntegrationsStore` (provider config, connections, labels, messages, tombstones, sync state, action logs), to the secret store (client secret and per-connection credentials through `GoogleTokenProvider`), to Google (token revocation) and to Gmail (`batchModify`).
- **no-timeouts-owned**: The service MUST NOT impose its own timeout, retry or pacing on Gmail calls; those belong to `GmailRESTClient` and its pacer, and the one timeout it owns is `stop(timeout:)`.

## Appearance

Not applicable — this is a Gmail service actor, not a visual component.

## States

Not applicable — this is a Gmail service actor, not a visual component.

## Accessibility

Not applicable — this is a Gmail service actor, not a visual component.

## Conformance Test Vectors

Vectors are drawn from `MailIntegrationServiceTests` (the test name is given) and, where marked derived, from the code only.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| mail-service-001 | request-data-decoding, dispatch-listAccounts | `handle(requestData:)` with the encoded `.listAccounts` and no accounts (`requestRoundTripsThroughData`) | Decodes as `.accounts([])` |
| mail-service-002 | bad-request | `handle(requestData:)` with the bytes `nope` (`undecodableRequestIsBadRequest`) | Decodes as `.failure("bad request")` |
| mail-service-003 | oauth-config-required, error-to-failure | `.signIn` with no provider imported (`signInWithoutProviderFails`) | `.failure` whose message contains `not configured`; the sign-in flow is called 0 times |
| mail-service-004 | status-configured, secret-never-leaves, secret-suffix-rule | Import a client with secret `GOCSPX-abcdefghij12345`, then `.providerStatus` (`providerStatusShowsOnlyTheLastFiveCharactersOfTheSecret`) | `configured: true`, `clientSecretSuffix: "12345"`; the encoded response does not contain `GOCSPX` |
| mail-service-005 | secret-suffix-rule | `visibleSuffix(ofSecret:)` with "", 14 characters and 15 characters (`visibleSuffixKeepsAtLeastTwiceAsMuchHidden`) | nil, nil, `12345` |
| mail-service-006 | sign-in-reuses-account, sign-in-email-key | Sign in, then sign in again with the same email in another case (`reSignInWithDifferentCaseReusesAccount`) | One account, same id, email lowercased |
| mail-service-007 | sign-in-credential-first | Sign in when the Keychain write for the credential fails (`signInFailsWithoutLeavingAConnectionWhenCredentialCannotBeSaved`) | The request fails; no connection exists |
| mail-service-008 | sign-in-starts-sync, due-rule | Sign in, advance the clock 14 minutes, `runDueSyncs`, then 1 more minute and `runDueSyncs` (`runDueSyncsRespectsPollInterval`) | No Gmail labels call after 14 minutes; one more after 15 minutes; `lastSyncAt` is the start plus 15 minutes |
| mail-service-009 | record-error, due-rule, last-attempt-memory | Make the labels call fail with a 500, advance 15 minutes and run due syncs, then advance 1 minute, then 14 more (`failedSyncRetriesAtPollIntervalNotEveryTick`) | Status `error`; no new call after 1 minute; one new call after the next 14 |
| mail-service-010 | due-malformed-last-sync | Set `lastSyncAt` to `garbage`, advance 1 then 14 minutes (`malformedLastSyncAtCountsAsNeverSynced`) | No call after 1 minute; one new call after 15 minutes from the attempt |
| mail-service-011 | record-revoked | A sync fails with `IntegrationError.revoked` (`revokedTokenMarksAccountRevokedAndStopsSyncing`) | Status `revoked`; later due runs do not sync it |
| mail-service-012 | sync-now-bypasses-due | `syncNow` before the interval has passed (`syncNowBypassesDueness`) | The sync runs |
| mail-service-013 | settings-tombstone-classes | Turn off `includeArchived` on an account with archived rows (`disablingArchivedTombstonesArchivedRows`) | Archived rows are tombstoned |
| mail-service-014 | settings-widen-clears-cursor | Enable `includeSpam`, then widen `windowDays` (`enablingSpamClearsCursor`, `wideningWindowClearsCursor`) | `syncCursor` becomes nil each time |
| mail-service-015 | settings-tombstone-window | Shrink `windowDays` (`shrinkingTheWindowTombstonesRowsThatFellOutOfIt`) | Rows older than the new window are tombstoned at once |
| mail-service-016 | settings-validated | `.updateSettings` with `windowDays` 0, then `pollIntervalMinutes` 1441 (`invalidSettingsFail`) | `.failure` with `Invalid sync settings: windowDays must be 1–3650, got 0`, then the poll interval message |
| mail-service-017 | settings-unchanged | `.updateSettings` with settings equal to the stored ones (`unchangedSettingsDoNotQuiesceOrResync`) | The account is returned; no sync is cancelled or started |
| mail-service-018 | settings-resync | `.updateSettings` on a revoked account (`updateSettingsOnRevokedAccountSavesWithoutSyncing`) | The settings are saved; no sync starts |
| mail-service-019 | modify-payload, write-refetch | `.modifyLabels` adding a label by name (`modifyLabelsResolvesNamesAndRefreshesMessages`) | Gmail gets the label id; the messages are re-read and stored; the page has `nextCursor` nil |
| mail-service-020 | modify-resolves-first | `.modifyLabels` with an unknown label, then an unknown message (`modifyLabelsRejectsUnknownLabelBeforeCallingGmail`, `modifyLabelsRejectsUnknownMessageBeforeCallingGmail`) | `.failure("unknown label: ...")`, then `notFound`; no `batchModify` call |
| mail-service-021 | modify-noop | `.modifyLabels` with empty `add` and `remove` (`modifyLabelsWithNoLabelsReturnsMessagesUnchanged`) | Messages returned unchanged; no Gmail write |
| mail-service-022 | batch-chunking | `.modifyLabels` for 2,500 message ids (`modifyLabelsChunksBatchModifyAtOneThousand`) | `batchModify` calls of 1,000, 1,000 and 500 ids, in order; 2,500 messages returned |
| mail-service-023 | move-default-sources, move-single-write | `.moveMessages` to a label with `from` nil (`moveAddsTheDestinationAndRemovesInboxInOneWrite`) | One write adds the destination and removes `INBOX` |
| mail-service-024 | move-default-sources | `.moveMessages` to `INBOX` with `from` nil (`moveToInboxWithNoFromOnlyAddsInbox`) | One write adds `INBOX`, removes nothing; `added` is `["INBOX"]`, `removed` is empty |
| mail-service-025 | move-result, move-skips-unchanged | Move a message that already has the destination and no source (`moveToALabelTheMessageAlreadyHasAddsNothing`) | `added` is empty; no write for it |
| mail-service-026 | move-reads-gmail-first | Move a message whose local copy is stale (`moveReadsGmailFirstSoAStaleCopyStillLosesItsInbox`) | The message still loses `INBOX` |
| mail-service-027 | move-result, move-skips-unchanged | Move messages when Gmail has lost one (`moveSkipsMessagesAlreadyMovedAndLeavesOutOnesGmailLost`) | The lost one is absent from the results; an already-moved one is not written |
| mail-service-028 | write-failure-rethrown, write-action-log | A `batchModify` failure (`moveBatchFailureLogsAnError`, `modifyLabelsBatchFailureLogsHowManyWereApplied`) | Action log status `error` with the applied count; the error returned |
| mail-service-029 | refetch-failure | The re-read after a write fails (`modifyLabelsRefetchFailureLogsOkAndReportsAppliedLabels`) | Action log status `ok` with `refreshError`; `.failure` starting `labels applied; refreshing messages failed:` |
| mail-service-030 | store-refetched, suspension-rechecks | Settings change while a write's re-read is held (`modifyLabelsRefetchHonoursSettingsChangedMeanwhile`) | The message the new settings no longer mirror is not live afterwards |
| mail-service-031 | store-refetched | The account is removed while the re-read is held (`modifyLabelsRefetchSkipsWritesAfterAccountRemoved`) | No rows are written for the removed account |
| mail-service-032 | resolve-messages, resolve-not-found, resolve-not-stored | `.getMessage` for a tombstoned row, then a never-synced Gmail id (`aMessageTheMirrorTombstonedIsStillFoundInGmail`, `aMessageNeverSyncedIsReadFromGmailAndAMissingOneIsNotFound`) | Both found through Gmail; an id Gmail lacks answers `notFound` |
| mail-service-033 | body-text-fallback | A message with only HTML, a text part, and a blank text part (`htmlOnlyMessageGetsBodyTextReadFromItsHTML`, `textPartWinsOverHTMLForBodyText`, `blankTextPartFallsBackToHTML`) | Body text is the HTML as text; the text part; `Bold text` for `<b>Bold</b> text` |
| mail-service-034 | limit-clamp, page-extra-row, cursor-keyset | `MailMessageFilter` limit 0 and 9,999; page a list (`messageFilterClampsLimit`, `listMessagesFiltersAndPages`) | Limits 1 and 500; default 50; pages continue after the last row of the previous page |
| mail-service-035 | labels-all-of, applied-any-labels | `listMessages` with `anyLabels` (`listMessagesMatchesAnyOfAnyLabels`) | Messages with any of them; `appliedAnyLabels` true |
| mail-service-036 | label-resolution | `listMessages` with an unknown label (`listMessagesRejectsUnknownLabel`) | `.failure` with `unknown label: <value>` |
| mail-service-037 | label-refresh, move-resolves-labels | A move to a label created in Gmail since the last sync (`aLabelMadeInGmailSinceTheLastSyncIsFoundForAMove`) | The labels are re-read and stored; the move succeeds |
| mail-service-038 | search-bounds, search-no-bounds, search-bound-invalid | `gmailQuery("from:a OR from:b", since: nil, until: nil)`, and `gmailQuery("x", since: "yesterday", until: nil)` (`aQueryWithNoBoundsIsSentAsWritten`) | The first returns the query unchanged; the second throws |
| mail-service-039 | search-trigger, search-order, search-cursor-prefix, search-not-stored | `listMessages` with a `query` and dates and labels (`aQuerySearchesGmailWithItsDatesAndLabelsAndPagesByGmailsToken`) | Gmail is searched with the bounds and label ids; `nextCursor` is `gmail:` plus the token |
| mail-service-040 | search-any-label-refused, search-cursor-prefix, cursor-invalid | A query with `anyLabels`; a query with cursor `123\|abc`; a plain list with cursor `gmail:p1` (`aQueryRefusesAnyLabelsAndCursorsFromTheOtherKindOfList`) | The three failures listed in those requirements; no Gmail search call |
| mail-service-041 | search-trigger, list-source | `listMessages` with a blank query (`aBlankQueryListsTheSyncedMail`) | The synced mirror is listed |
| mail-service-042 | thread-known-message, thread-unknown-id, thread-gone | `.getThread` by message id, Gmail message id, thread id; and an unsynced missing id (`aThreadComesFromGmailOldestFirstWhicheverIdNamesIt`, `aThreadByAnUnsyncedMessageIdIsFoundAndAMissingOneIsNotFound`) | The thread, oldest first, for each of the first three; `notFound` for the last |
| mail-service-043 | remove-account-order | `.removeAccount` (`removeAccountRevokesTheRefreshTokenThenForgetsIt`) | The refresh token is revoked at Google; the Keychain entry is gone |
| mail-service-044 | remove-account-revoke-best-effort | `.removeAccount` when Google refuses the revoke (`removeAccountSucceedsWhenGoogleRefusesTheRevoke`) | `.ok`; no accounts remain |
| mail-service-045 | remove-account-no-sync | A due run and `syncNow` while a removal is held at the revoke call (`anAccountBeingRemovedIsNotSynced`) | No Gmail call is made; the removal ends with `.ok` |
| mail-service-046 | remove-provider-accounts | `.removeProvider` (`removeProviderClearsEverything`) | `.ok`; accounts, provider config and secret are gone |
| mail-service-047 | remove-provider-fence, sign-in-blocked-during-removal | A sign-in begun while a provider removal awaits (`aSignInStartedWhileGmailIsBeingRemovedIsRefused`) | The sign-in is refused |
| mail-service-048 | sign-in-provider-removed | The provider is removed during the profile fetch, and during the browser flow (`gmailRemovedDuringTheProfileFetchRevokesTheFreshGrant`, `gmailRemovedDuringTheBrowserFlowRevokesTheGrantItStillIssued`) | The sign-in is cancelled; no account is created; the grant is revoked at Google |
| mail-service-049 | sign-in-supersedes, dispatch-cancelSignIn | A second sign-in while one is pending, then `.cancelSignIn` with and without a pending one (`aSecondSignInSupersedesThePendingOneAndCancelSignInEndsIt`) | The first sign-in is cancelled; `.cancelSignIn` answers `.ok` both times |
| mail-service-050 | keychain-read-failure, record-error | The Keychain is locked and a due sync runs (`aKeychainReadFailureMarksTheAccountErrorNotRevoked`) | Status `error`, `lastError` is `Keychain error: Could not read the Google credential: locked` |
| mail-service-051 | record-revoked | A token refresh answers invalid grant (`invalidGrantOnRefreshMarksAccountRevoked`) | Status `revoked` |
| mail-service-052 | stop-bounded-wait | `stop(timeout: .milliseconds(200))` while a sync ignores cancellation (`stopGivesUpOnASyncThatIgnoresCancellation`) | `stop` returns after about 200 milliseconds |
| mail-service-053 | stop-cancels | `stop()` with syncs running (`stopWaitsForTheCancelledSyncsToEnd`) | Every running sync is cancelled and has ended when `stop` returns |
| mail-service-054 | start-loop, loop-weak-self | `start(tick:)` then `stop`; and a started service that is released (`schedulerTicksAndStops`, `schedulerDoesNotRetainService`) | The observer sees ticks and the loop ends; the service is deallocated and the loop ends |
| mail-service-055 | sync-now-joins, one-sync-per-connection | `syncNow` while a scheduled sync runs (`syncNowDuringScheduledSyncRunsOnce`) | The sync runs once; the observer sees `.joinedRunningSync` |
| mail-service-056 | sync-now-not-syncable | Derived: `syncNow` for a named account whose status is `revoked`, and for one in another non-syncable status | `.failure` with the revoked message; `account <email> is not ready to sync` |
| mail-service-057 | account-resolution | Derived: `.listLabels` with an account that matches no id or email | `.failure` with `No connected account matches “<account>”` |
| mail-service-058 | import-keychain-failure | Derived: `.importOAuthClient` when the secret store refuses the write | `.failure("Could not save the OAuth client secret to the Keychain")`; no provider config row |
| mail-service-059 | cursor-invalid | Derived: `decodeCursor("abc")`, `decodeCursor("|x")`, `decodeCursor("1|")` | Each throws `invalid cursor: <value>` |
| mail-service-060 | move-conflict | Derived: `.moveMessages` with destination `Work` and `from` containing `Work` | `.failure("cannot move to Work: it is also a label to move from")` |
| mail-service-061 | move-empty | Derived: `.moveMessages` with an empty `messageIds` | `.moved([])` |
| mail-service-062 | encoding-fallback | Derived: a response that fails to encode in `handle(requestData:)` | The bytes of `{"failure":{"_0":"encoding failed"}}` |
| mail-service-063 | search-bounds | Derived: `gmailQuery("x", since: "2026-01-01T00:00:00Z", until: "2026-01-02T00:00:00Z")` | `(x) after:1767225600 before:1767312001` |
| mail-service-064 | sign-in-profile-failure-no-revoke | The Gmail profile call throws `revoked` during `.signIn` (`revokedProfileAtSignInFails`) | `.failure("Google access was revoked — sign in again")`; no connection is stored; the grant is not revoked at Google |

## Edge Cases

- **Null and empty input**: A `listMessages` filter with no labels, no query and no cursor MUST list the first page of the mirror. A blank `query` MUST be treated as no query. `.modifyLabels` with empty ids and labels MUST return without a write (modify-noop). An empty `from` on a move MUST remove nothing (move-default-sources).
- **Boundary values**: A limit below 1 MUST become 1 and above 500 MUST become 500. `windowDays` 1 and 3650, and `pollIntervalMinutes` 1 and 1440, MUST be accepted; 0 and 3651, and 0 and 1441, MUST be refused. A secret of exactly 15 characters MUST show its last 5; 14 MUST show nothing. A 2,500-id write MUST split into 1,000, 1,000 and 500.
- **Malformed input**: Undecodable request bytes MUST answer `bad request`. A malformed cursor, an unknown label, an unknown account and a non-ISO date on a search MUST each fail with their message and no Gmail write. A stored `lastSyncAt` that does not parse MUST count as never synced.
- **Error states**: A Gmail 400 or 404 on a message or thread MUST become `notFound`. A revoked error on any Gmail path MUST set the account `revoked`. A refresh or other sync error MUST set status `error` and retry at the poll interval, not every tick. A Keychain read failure MUST surface as `keychain`, never as "not configured".
- **Partial failure**: A write that reaches Gmail but cannot refresh the mirror MUST still log `ok` and tell the caller `labels applied`. A write that fails partway across chunks MUST log how many ids were already applied; the earlier chunks stay applied because Gmail is not rolled back.
- **Concurrent access**: Requests run on one actor, so state changes are serialised, but every `await` is a suspension point. A second sync for a connection MUST be refused or joined; a second sign-in MUST supersede the first; a second removal of an account MUST return at once; a sync MUST NOT start for an account or provider being removed; a sign-in that began before a provider removal MUST NOT bring the account back (provider generation check).
- **Cancellation**: `cancelSignIn`, `removeProvider`, `updateSettings` and `stop` MUST cancel the work they interrupt. A cancelled sync MUST record nothing. A sync that ignores cancellation MUST NOT hold `stop` beyond its timeout; it is left running.
- **Offline or unreachable Gmail**: The service has no offline mode: a Gmail or Google failure surfaces as `.failure` for a request, as `error` status for a sync, and the next poll retries. The mirror-backed reads (`listAccounts`, `listLabels` with known labels, `listMessages` without a query whose labels are all known) MUST keep answering from the store.
- **Store failures on background paths**: When the scheduler cannot read connections it starts nothing and the loop continues; when recording a sync failure cannot write, the failure status is lost (`status-write-errors`, `scheduler-store-read`; rationale in the Design Decision on swallowed store failures).
- **Lossy sign-in**: When the Gmail profile call fails after Google issued a grant, the request fails and the grant is not revoked at Google in this path (`sign-in-profile-failure-no-revoke`).

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| store | `IntegrationsStore` | required | Connections, provider config, labels, messages, tombstones and action logs. |
| secrets | `any SecretStoring` | required | Keychain wrapper for the client secret and per-connection credentials. |
| signIn | `any GoogleSignInFlow` | `AppAuthGoogleSignIn()` | Runs the browser OAuth flow and returns a `GoogleCredential`. |
| tokenEndpoint | `any GoogleTokenEndpoint` | `URLSessionGoogleTokenEndpoint()` | Refreshes and revokes Google tokens. |
| makeAPI | closure from an access-token provider to `any GmailAPI` | builds `GmailRESTClient` | Factory for the Gmail client used by syncs, searches, threads and writes. |
| now | `@Sendable () -> Date` | `Date.init` | Clock for due-ness, window starts and the sync worker. |
| tick | `Duration` | 60 seconds | Interval between scheduler passes (`start`). |
| timeout | `Duration` | 5 seconds | Longest `stop` waits for cancelled syncs. |
| refetchConcurrency | constant | 8 | Messages re-read from Gmail at once. |
| MailSyncSettings | per connection | `includeArchived` false, `includeSpam` false, `includeTrash` false, `windowDays` 30, `pollIntervalMinutes` 15 | Which mail classes and how many days the mirror keeps and how often it polls. |
| MailMessageFilter.limitRange | constant | 1...500, default 50 | Page size bounds. |

There are no environment variables or settings keys read by this file.

## Deep Linking

Not applicable: the service has no URL scheme or route; its only entry points are `handle(_:)` and `handle(requestData:)`.

## Localization

Every user-facing error is a hardcoded English string, not a localised key.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none (inline) | `bad request` | `MailClient.badRequest`, an undecodable request |
| none (inline) | `Could not save the OAuth client secret to the Keychain` | Import cannot write the secret |
| none (inline) | `Could not read the OAuth client secret: <cause>` | Keychain read failure |
| none (inline) | `a query can't be combined with any-label; write {label:a label:b} in the query` | Search with `anyLabels` |
| none (inline) | `invalid cursor: <cursor>` | Malformed mirror or search cursor |
| none (inline) | `invalid since: <text>` / `invalid until: <text>` | Search bound not ISO 8601 |
| none (inline) | `unknown label: <value>` | Label resolution failure |
| none (inline) | `account <email> is not ready to sync` | `syncNow` on a non-syncable account |
| none (inline) | `account <email> was removed` | Label refresh after the account vanished |
| none (inline) | `cannot move to <destination>: it is also a label to move from` | Move conflict |
| none (inline) | `labels applied; refreshing messages failed: <message>` | Re-read failed after a write |
| none (inline) | `No connected account matches “<account>”` | `IntegrationError.unknownAccount`, an account that matches no id or email |
| none (inline) | `Invalid sync settings: <reason>` (for example `windowDays must be 1–3650, got <n>`) | `IntegrationError.invalidSettings`, a refused `updateSettings` |
| none (inline) | `encoding failed` | Response could not be encoded |

The `IntegrationError` cases (`notConfigured`, `unknownAccount`, `revoked` and the rest) supply their own English `errorDescription` in the Model layer.

## Accessibility Options

Not applicable: the service has no display, motion or color and responds to no accessibility setting.

## Feature Flags

Not applicable: the source reads no feature flag; behavior varies only by injected dependencies and per-connection `MailSyncSettings`.

## Analytics

Not applicable: the source emits no analytics events. `MailServiceEvent` (`schedulerTick`, `joinedRunningSync`) is an internal observer hook for tests and is not analytics.

## Privacy

- **Data collected**: Email addresses of connected accounts, Gmail message metadata, snippets and (on request) bodies, label names, and the Google OAuth client id.
- **Storage**: The OAuth client secret and each account's Google credential are stored in the Keychain through `SecretStoring` (`GoogleTokenProvider.clientSecretKey` and `GoogleTokenProvider.key(connectionId:)`). Connections, labels, mirrored messages and action logs are stored in `IntegrationsStore`. Searches, threads and messages read only to resolve an id are not stored.
- **Transmission**: Requests go to Google's token endpoint and to Gmail through the injected `GmailAPI`. A reply to a client never carries the client secret beyond its last 5 characters, and only when the secret has at least 15 characters; action log payloads hold message ids and label ids, not bodies.
- **Retention**: Mirrored mail is kept for `windowDays` (default 30) and only for allowed classes; older or disallowed rows are tombstoned. Removing an account revokes its Google grant (best effort), deletes its credential and connection; removing the provider also deletes the client config and secret.

## Logging

Subsystem: `com.agenticdeveloperhub.integrations` | Category: `Mail`

| Event | Level | Message |
|-------|-------|---------|
| Revoking a discarded sign-in's grant at Google failed | error | `Revoking a discarded sign-in at Google failed: <error>` |

This is the only log call in the file. Sync failures are recorded on the connection (`status`, `lastError`), not logged; a failed `batchModify` is recorded in the action log table, not in the system log.

## Platform Notes

- **SwiftUI**: Not a view. A SwiftUI app talks to the service through `MailClient` and `MailDaemonTransport` and renders `MailAccount.status`, `lastSyncAt` and `lastError`; hold results in an `@Observable` model refreshed after `handle`, and call `syncNow` for a manual refresh. The service has no `ObservableObject` or Combine dependency.
- **Compose**: Port as a Kotlin class with `suspend fun handle(request: MailRequest): MailResponse` and a `Mutex` (or a single-threaded `CoroutineDispatcher`) in place of actor isolation. Keep a `MutableMap` of running jobs keyed by connection id, a `CoroutineScope` and `Job` for the poll loop with `delay(tick)`, and `Job.cancel()` plus `withTimeoutOrNull(timeout)` around `joinAll()` for `stop`. Model `MailRequest` and `MailResponse` as sealed interfaces serialised with `kotlinx.serialization`. Store secrets in `EncryptedSharedPreferences` or the Android Keystore, rows in Room with a transaction per write, and run the browser OAuth flow with AppAuth for Android or Custom Tabs.
- **React/Web**: Port as a TypeScript class whose methods are `async`. JavaScript is single-threaded, so a `Map` of running promises needs no lock, but every `await` is still a point where state must be re-read, exactly as the Swift code does. Use `setInterval` or a self-rescheduling `setTimeout` for the poll loop, `AbortController` for cancelling sign-in and syncs, and `Promise.race` against a timer for `stop`. Keep the client secret and tokens server-side, because a browser cannot hold a client secret safely; use `fetch` for Gmail and an 8-wide worker-pool helper for re-reads.
- **AppKit / UIKit**: Source platform. The service is an `actor` that imports `AgenticDeveloperHubSDKCore`, `AIPluginKit`, `Foundation` and `os`. It uses structured concurrency (`Task`, `withTaskCancellationHandler`, `withThrowingTaskGroup` refilled by a nested `addNext()`), a `Logger` for the one log line, a nonisolated entry point for the JSON transport, and a small `RaceBox` for the timed `stop`. It depends on `IntegrationsStore` (GRDB-backed and synchronous), `SecretStoring` (Keychain), `AppAuthGoogleSignIn` for the browser flow and `URLSession` for token calls. `MailRPC.swift` in the same folder defines `MailRequest`, `MailResponse`, `MailMessageFilter`, `MailClient` and the wire types; `MailIntegrationServiceTests` in `Tests/AgenticDeveloperHubSDKIntegrationsTests` is the test file, using a fake Gmail API, a controllable clock and gates to force interleavings.
- **WinUI 3**: Write a `sealed class MailIntegrationService` hosted by an `IHostedService`: `StartAsync` starts the poll loop with `PeriodicTimer(tick)`, and `StopAsync` cancels a linked `CancellationTokenSource` and awaits `Task.WhenAny(Task.WhenAll(syncs), Task.Delay(timeout))`. Replace actor isolation with a `SemaphoreSlim(1, 1)` around state mutations and re-read state after each `await`, as the Swift code does. Expose `Task<MailResponse> HandleAsync(MailRequest request, CancellationToken ct)` and a byte-array overload using `System.Text.Json` (`JsonSerializer.Deserialize` with a `JsonDerivedType` hierarchy for the request, answering the literal bad-request response on a `JsonException`). Hold running syncs in a `ConcurrentDictionary<string, Task>`. Use `HttpClient` for Gmail and Google, `SemaphoreSlim(8)` with `Task.WhenAll` for the 8-wide re-read, `Windows.Security.Credentials.PasswordVault` or DPAPI (`ProtectedData`) for the client secret and credentials, and a loopback `HttpListener` with the system browser (or `WebAuthenticationBroker`) for sign-in. Persist with `Microsoft.Data.Sqlite` or Entity Framework Core, one transaction per store call. Surface `status` and `lastError` to the UI through an `INotifyPropertyChanged` view model fed by an `ObservableCollection` of accounts; the service itself exposes no observable state.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Integrations/Service/MailIntegrationService.swift` | unverified |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Cancel a pending sign-in when a new one starts, instead of refusing the new one.
**Rationale**: The source comment says a pending sign-in belongs to a client that gave up on it, such as a closed panel or a crashed app, and refusing would "lock Add Account out until the browser flow times out". Cancelling the old flow also closes its redirect listener so its abandoned tab cannot add an account.
**Approved**: pending

**Decision**: Fence provider removal with a generation counter and a removal counter, and re-check them after each await in sign-in.
**Rationale**: Per the comments, a sign-in under way when Gmail is removed would otherwise save a credential and bring the account back, and one starting during the removal would capture the already-bumped generation and pass every check. The cost is extra state and a revoke of the grant Google already issued.
**Approved**: pending

**Decision**: Store the credential before the connection row.
**Rationale**: The comment states this so a failed Keychain write leaves no active connection without a credential. The connection is then re-read after that await, so sync state written meanwhile is not rolled back.
**Approved**: pending

**Decision**: Keep last-attempt time in memory only and take the later of it and `lastSyncAt` for due-ness.
**Rationale**: The comment says a failing account then retries at the poll interval, not every tick. After a restart, due-ness falls back to `lastSyncAt`, so a failing account is retried at once; the source accepts that.
**Approved**: pending

**Decision**: Distinguish a locked or denied Keychain from "not configured".
**Rationale**: The comment says a read failure throws, "rather than reading as 'not configured' and sending the user to import a client they already have".
**Approved**: pending

**Decision**: Answer every failure as a `MailResponse` and mark unknown messages `notFound` inside `.failure`.
**Rationale**: A transport cannot carry a thrown error; `notFound` rides inside `.failure` so an older client still decodes it as a failure (`notFoundStillDecodesAsAFailureForAnOlderClient`).
**Approved**: pending

**Decision**: Page the mirror with a keyset cursor of internal date and id, not an offset.
**Rationale**: The comment says a sync or label change between pages moves rows in and out of the filter, and an offset would skip or repeat messages. Search cursors carry a `gmail:` prefix so each path refuses the other's cursor.
**Approved**: pending

**Decision**: Read Gmail before a move and write the same label change for every message.
**Rationale**: The comment says Gmail ignores removing a label a message lacks, and the local copy may be up to a sync interval old, so `added` and `removed` come from the fresh read and an already-moved message is not written.
**Approved**: pending

**Decision**: Treat a failed re-read after a label write as success logged `ok`, but still return a failure to the caller.
**Rationale**: The comment says the change is in Gmail so the action succeeded; the caller is told the labels applied and the refresh failed, so it does not repeat the write.
**Approved**: pending

**Decision**: Resolve ids missing from the mirror through Gmail without storing them.
**Rationale**: The mirror holds only the classes and window a connection syncs; a trashed, aged-out or never-synced message must still be readable. A write stores it only if it is mirrored.
**Approved**: pending

**Decision**: Quiesce a connection's sync (cancel and await) before changing its settings or removing it.
**Rationale**: A running sync would write back a cursor taken under the old settings, or recreate state for a removed account.
**Approved**: pending

**Decision**: Bound `stop` with a timeout rather than await syncs indefinitely.
**Rationale**: The comment says a sync stuck in a call that ignores cancellation must not hold up shutdown. The cost is that such a sync is left running when `stop` returns.
**Approved**: pending

**Decision**: Accept swallowed store failures on background paths for now, instead of logging or signalling them.
**Rationale**: `startDueSyncs` reads connections with `try?`, `performSync` skips when the connection read fails, and `record` writes status with `try?`. A store outage therefore appears as no sync and no status change, not as an error. Revisit when a store failure needs to be visible to a user; until then a port should keep the behavior or log it as a deliberate change.
**Approved**: pending

**Decision**: Accept that a Gmail profile failure during sign-in leaves the issued grant unrevoked, instead of revoking it.
**Rationale**: Only the provider-removed paths revoke the discarded credential; a profile error (`sign-in-profile-failure-no-revoke`) leaves the grant at Google. Revisit when sign-in failures are reported to users; until then a port must either match this or change it deliberately.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.security.secure-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bb5dfc9b-c5b0-54fa-882f-007ae7dad0e9) | passed | security |
| [adc.check.security.token-lifecycle](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/61edfc73-f26a-5cfa-8c09-d1011eb8b7cd) | partial | security |

The service separates concerns by composing injected parts: the store, Keychain, sign-in flow, token endpoint, Gmail client factory and clock are all parameters, and sync, parsing, transport, retry and pacing live in other types, so it can be tested against fakes. Unit-test coverage is partial: `MailIntegrationServiceTests` covers requests, sign-in, removal, settings, scheduling, searching, threads and writes, with gates for the interleavings, but vectors mail-service-056 to 063 are derived from the code and not asserted by a named test. Explicit error handling is partial: most errors surface as `.failure` or connection status, but `startDueSyncs`, `performSync` and `record` swallow store failures with `try?`, which the Design Decision on swallowed store failures records. Secure storage passes because the client secret and credentials go to the Keychain, only a 5-character suffix of the secret is ever returned, and a Keychain read failure is not mistaken for absence. Token lifecycle is partial: the service revokes grants on account and provider removal and on a discarded sign-in, and marks accounts `revoked` on a revoked response, but a profile failure at sign-in leaves the issued grant unrevoked, and refresh lifetimes are owned by `GoogleTokenProvider`, outside this file.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
