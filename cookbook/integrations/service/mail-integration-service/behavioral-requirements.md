
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

