
### MailRequest

- **request-cases**: `MailRequest` MUST offer exactly these cases: `providerStatus`, `importOAuthClient(json:)`, `removeProvider`, `listAccounts`, `signIn`, `cancelSignIn`, `removeAccount(account:)`, `updateSettings(account:settings:)`, `syncNow(account:)`, `listLabels(account:)`, `listMessages(_:)`, `getMessage(account:id:)`, `getThread(account:id:includeBodies:)`, `modifyLabels(account:messageIds:add:remove:)` and `moveMessages(account:messageIds:destination:from:)`.
- **request-conformances**: `MailRequest` MUST be `Codable`, `Sendable` and `Equatable`, and so MUST `MailResponse` and every record type in this file.
- **request-account-argument**: Every `account` argument MUST accept either a connection id or an email address (the type's own comment).
- **request-sign-in-exclusive**: The `signIn` case MUST be documented as running the browser flow in the service's process and as refused while another sign-in is pending (the case's comment); the service (MailIntegrationService ([adhsdk.ingredient.integrations.service.mail-integration-service](cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a))) enforces it, and this file only declares it.
- **request-cancel-sign-in**: The `cancelSignIn` case MUST be documented as ending a pending sign-in, which then answers "Sign-in was cancelled", and to be harmless when none is pending (the case's comment); the service (MailIntegrationService ([adhsdk.ingredient.integrations.service.mail-integration-service](cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a))) enforces it.
- **request-sync-all**: The `syncNow` case MUST be documented as syncing every account when `account` is `nil` (the case's comment); the service (MailIntegrationService ([adhsdk.ingredient.integrations.service.mail-integration-service](cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a))) does the syncing.
- **request-message-id**: `getMessage` MUST accept either this system's message id or Gmail's (the case's comment).
- **request-thread-id**: The `getThread` case MUST be documented as taking a Gmail thread id, or a message id (this system's or Gmail's) that stands for the thread it is in; the service (MailIntegrationService ([adhsdk.ingredient.integrations.service.mail-integration-service](cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a))) reads the conversation from Gmail, oldest message first (the case's comment).
- **request-modify-labels-ids**: `modifyLabels` MUST name messages by this system's id or Gmail's, and labels by Gmail label id or exact name (the case's comment).
- **request-move-semantics**: The `moveMessages` case MUST be documented as adding `destination` and removing every label in `from`; a `nil` `from` means INBOX, or nothing when `destination` is INBOX, and an empty `from` removes nothing (the case's comment). The service (MailIntegrationService ([adhsdk.ingredient.integrations.service.mail-integration-service](cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a))) enforces this rule; this file only declares it.
- **request-wire-form**: A request MUST travel as the JSON that the synthesized `Codable` conformance produces for the enum: an object with one key, the case name, whose value is an object of the case's payload. A case with no payload has an empty object, as in `{"listAccounts":{}}`. A case with labeled arguments has one key per label, as in `{"getMessage":{"account":"a","id":"m"}}`. A case with one unlabeled argument uses the key `_0`, as in `{"listMessages":{"_0":{"account":"a"}}}`. The tests decode replies of the same form, such as `{"messages":{"_0":{"messages":[]}}}` and `{"failure":{"_0":"boom"}}`.

### isMailboxAccess

- **mailbox-access-true**: `isMailboxAccess` MUST be true for `listAccounts`, `listLabels`, `listMessages`, `getMessage`, `getThread`, `modifyLabels` and `moveMessages`.
- **mailbox-access-false**: `isMailboxAccess` MUST be false for `providerStatus`, `importOAuthClient`, `removeProvider`, `signIn`, `cancelSignIn`, `removeAccount`, `updateSettings` and `syncNow`.
- **mailbox-access-purpose**: `isMailboxAccess` MUST be true exactly for the requests that read or label mail in accounts already signed in; the false side is what a host keeps for its own UI. Which consumers send which requests is left to their own specs.
- **mailbox-access-exhaustive**: The classification MUST be an exhaustive switch with no default, so a new request cannot compile until it is placed on one side.

### MailMessageFilter

- **filter-fields**: `MailMessageFilter` MUST carry `account` (required), `since`, `until`, `labels`, `anyLabels`, `limit`, `cursor`, `includeBodies` and `query`.
- **filter-since-until**: `since` and `until` MUST be documented as inclusive ISO-8601 strings (the type's comment). They are stored as plain `String` and this file does not parse or validate them; see the Design Decision on raw date text.
- **filter-labels-and**: The filter MUST be documented as listing only messages that carry every entry of `labels`, given as ids or names (the type's comment); the service (MailIntegrationService ([adhsdk.ingredient.integrations.service.mail-integration-service](cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a))) enforces it.
- **filter-any-labels-or**: The filter MUST be documented as listing, when `anyLabels` is not empty, only messages that also carry at least one entry of `anyLabels`; the service (MailIntegrationService ([adhsdk.ingredient.integrations.service.mail-integration-service](cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a))) enforces it.
- **filter-cursor**: `cursor` MUST be the `nextCursor` of the previous page.
- **filter-query-gmail**: The filter MUST be documented as taking a `query` in Gmail's search syntax (`from:greenhouse`), with the messages coming from a Gmail search instead of the synced copy, so they reach past the sync window and the synced classes; the service (MailIntegrationService ([adhsdk.ingredient.integrations.service.mail-integration-service](cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a))) enforces it.
- **filter-query-narrowing**: The filter MUST be documented as letting `since`, `until` and `labels` narrow a `query` (the type's comment); the service (MailIntegrationService ([adhsdk.ingredient.integrations.service.mail-integration-service](cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a))) applies them.
- **filter-query-any-labels-refused**: The filter MUST be documented as refused by the service (MailIntegrationService ([adhsdk.ingredient.integrations.service.mail-integration-service](cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a))) when a `query` comes with a non-empty `anyLabels`; the caller writes `{label:a label:b}` in the query instead (the type's comment).
- **filter-limit-range**: `MailMessageFilter.limitRange` MUST be 1 through 500 and `defaultLimit` MUST be 50.
- **filter-limit-clamp-init**: The initializer MUST clamp `limit` into `limitRange`.
- **filter-limit-clamp-set**: Assigning `limit` after construction MUST clamp it into `limitRange` through a `didSet` observer.
- **filter-decode-lenient**: Decoding MUST require only `account`; `labels` and `anyLabels` default to empty, `limit` to 50, `includeBodies` to false, and `since`, `until`, `cursor` and `query` to nil.
- **filter-decode-clamps**: Decoding MUST route `limit` through the initializer, so a decoded out-of-range `limit` is clamped.
- **filter-encode-keys**: Encoding MUST use the coding keys `account`, `since`, `until`, `labels`, `anyLabels`, `limit`, `cursor`, `includeBodies` and `query`.
- **filter-clamp-public**: `MailMessageFilter.clamp(_:)` MUST return its argument brought into `limitRange` (`min(max(limit, 1), 500)`). It is `public` so that every mail RPC server applies the same bound (the source's comment); `MailIntegrationService` calls it across the module boundary.
- **filter-search-query**: `searchQuery` MUST return `query` with surrounding whitespace and newlines trimmed, and nil when `query` is nil or trims to an empty string.

### Records

- **account-record**: `MailAccount` MUST carry `id`, `email`, `status` (a `ConnectionStatus`), `lastSyncAt`, `lastError` and `settings` (a `MailSyncSettings`); `lastSyncAt` and `lastError` are optional.
- **provider-status-record**: `MailProviderStatus` MUST carry `configured`, an optional `clientId` and an optional `clientSecretSuffix`.
- **provider-client-id-public**: `clientId` MUST be treated as not secret, because a desktop client id "appears in every sign-in URL" (the field's comment).
- **provider-secret-suffix**: `clientSecretSuffix` MUST hold only the last `secretSuffixLength` characters of the client secret, and `MailProviderStatus.secretSuffixLength` MUST be 5.
- **provider-secret-never-leaves**: The whole client secret MUST NOT leave the daemon (the field's comment); no field in this file carries it. The one value that carries a secret toward the service is the `json` of `importOAuthClient`.
- **visible-suffix-rule**: `visibleSuffix(ofSecret:)` MUST return the last `secretSuffixLength` characters of the secret only when the secret has at least `secretSuffixLength * 3` characters (15 today); a character is a Swift `Character`, a grapheme cluster (`String.count`), so a port that counts UTF-16 units differs for non-ASCII secrets and MUST count grapheme clusters to match, so that at least twice as many characters stay hidden, and nil otherwise.
- **label-record**: `MailLabel` MUST carry Gmail's label `id`, `name`, `type` ("system" or "user"), and optional `parentName`, `messagesTotal` and `messagesUnread`.
- **message-record**: `MailMessage` MUST carry `id` (this system's id), `gmailId`, `threadId`, `account` (the account's email address), `from`, `to`, `cc`, `labels` (Gmail label ids), `labelNames`, `subject`, `snippet`, `date`, `mailClass` (a `MailClass`), optional `bodyText`, optional `bodyHtml` and `attachments` (a list of `EmailAttachmentRef`).
- **message-wire-names**: `to` and `cc` MUST keep those names on the wire; the source's comment calls them "the wire names the RPC contract fixes".
- **message-label-names**: `labelNames` MUST be documented as `labels` mapped to names, falling back to the id (the field's comment); the service (MailIntegrationService ([adhsdk.ingredient.integrations.service.mail-integration-service](cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a))) fills it.
- **message-snippet**: `snippet` MUST be documented as Gmail's preview text with the HTML entities Gmail leaves in it decoded (the field's comment); the service (MailIntegrationService ([adhsdk.ingredient.integrations.service.mail-integration-service](cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a))) decodes it.
- **message-bodies**: `bodyText` and `bodyHtml` MUST be documented as filled by the service (MailIntegrationService ([adhsdk.ingredient.integrations.service.mail-integration-service](cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a))) only when bodies are asked for; `bodyText` is the `text/plain` part, or for a message without one its HTML read as text (`HTMLText`), and `bodyHtml` is the `text/html` part as sent.
- **page-record**: `MailMessagePage` MUST carry `messages`, an optional `nextCursor`, `appliedAnyLabels` and `appliedQuery`.
- **page-cursor**: `nextCursor` MUST be documented as opaque, passed back as the filter's `cursor`, and nil on the last page; the service (MailIntegrationService ([adhsdk.ingredient.integrations.service.mail-integration-service](cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a))) sets it.
- **page-applied-flags**: `appliedAnyLabels` MUST be true when the service applied the filter's `anyLabels`, and `appliedQuery` MUST be true when the page is the result of the filter's `query` searched in Gmail.
- **page-decode-lenient**: Decoding a `MailMessagePage` MUST require `messages` only; a missing `nextCursor` is nil and a missing `appliedAnyLabels` or `appliedQuery` is false.
- **thread-record**: `MailThread` MUST carry Gmail's thread `id` and `messages`, documented as oldest message first (the service (MailIntegrationService ([adhsdk.ingredient.integrations.service.mail-integration-service](cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a))) orders them), and a message carrying `SENT` is one the account wrote.
- **move-result-record**: `MailMoveResult` MUST carry the message's refreshed copy and the names of the labels it gained (`added`) and lost (`removed`), documented as measured against Gmail just before the write (by the service (MailIntegrationService ([adhsdk.ingredient.integrations.service.mail-integration-service](cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a)))); `added` is empty when the message already carried the destination.

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
- **client-typed-methods**: The client MUST offer `providerStatus()` (expects `.providerStatus`), `accounts()` (sends `listAccounts`, expects `.accounts`), `labels(account:)` (expects `.labels`), `messages(_:)` (expects `.messages`), `thread(account:id:includeBodies:)` (expects `.thread`), `message(account:id:)` (expects `.message`), `modifyLabels(account:messageIds:add:remove:)` and `moveMessages(account:messageIds:destination:from:)` (expects `.moved`). The administration requests (`importOAuthClient`, `signIn`, `cancelSignIn`, `removeAccount`, `updateSettings`, `syncNow`, `removeProvider`) have no typed method; a host sends them through `send(_:)` and receives the raw `MailResponse`, whose case depends on the request and is decided by the service (MailIntegrationService ([adhsdk.ingredient.integrations.service.mail-integration-service](cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a))).
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

- **sensitive-data**: This contract MUST be treated as carrying personal mail content (addresses, subjects, snippets, bodies, label names) and, in `importOAuthClient`, the OAuth client JSON that contains the client secret.
- **secret-exposure**: The only form of the client secret the replies carry MUST be `clientSecretSuffix`, produced by `visibleSuffix(ofSecret:)`.
- **transport-security-outside**: This file MUST NOT encrypt, sign or authenticate a request; confidentiality and caller authentication belong to the injected transport and to the service. Token lifetime, storage and revocation for the Gmail account belong to the service and are outside this file.
- **host-gating**: A host that exposes non-UI clients MUST gate them on `isMailboxAccess`, so that administration requests stay with the host's own UI (the property's comment; `MailRequestAccessTests` asserts both sides).

