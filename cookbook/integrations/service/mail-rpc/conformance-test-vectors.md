
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
| mail-rpc-018 | client-any-labels-ignored, page-decode-lenient, client-check-order | transport returns `{"messages":{"_0":{"messages":[]}}}`; call `messages` with `anyLabels: ["INBOX"]` (`aPageFromAServiceThatIgnoredAnyLabelsIsRefused`) | throws `MailClient.anyLabelsIgnored`; the same reply decodes to `MailMessagePage(messages: [], nextCursor: nil)` |
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
| mail-rpc-031 | filter-any-labels-or, filter-labels-and | service lists with `anyLabels: ["INBOX", "Nope"]` | the reply is `.failure("unknown label: Nope")` |
| mail-rpc-032 | filter-query-gmail, page-applied-flags | service lists with `query: " from:sender OR from:other "`, `labels: ["Work"]`, `limit: 2` | first page has `appliedQuery` true |
| mail-rpc-033 | request-wire-form | encode `MailRequest.listAccounts` and hand the bytes to the service's `handle(requestData:)` (`requestRoundTripsThroughData`) | the reply decodes as `MailResponse.accounts([])`, so the service decoded the request |
| mail-rpc-034 | response-cases, failure-not-found-factory | `MailResponse.notFound("x")` | equals `.failure("x", notFound: true)` |
| mail-rpc-035 | mailbox-access-exhaustive | add a `MailRequest` case with no entry in `isMailboxAccess` | the module fails to compile |

