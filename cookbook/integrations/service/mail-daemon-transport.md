---
id: eeb038a0-67f3-476a-b1cd-e93cdfc5e9dd
title: "MailDaemonTransport"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-13
modified: 2026-11-13
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Rules for a MailClient whose service lives in a daemon: per-request deadlines, no retry, empty-reply error, and the sentence each IPC failure becomes."
platforms:
  - swift
  - macos
tags:
  - mail
  - ipc
  - daemon
  - timeout
  - transport
depends-on:
  - fc9671be-170c-436e-9628-892624952191
related:
  - aed9acc9-6340-487b-acfb-b7b13f14e59a
references: []
approved-by: ""
approved-date: ""
---

# MailDaemonTransport

## Overview

`MailDaemonTransport` is a caseless enum of static members that turns a host's IPC call into a `MailClient` ([adhsdk.ingredient.integrations.service.mail-rpc](cookbook:fc9671be-170c-436e-9628-892624952191)) for a mail service running in a daemon (`MailIntegrationService`, [adhsdk.ingredient.integrations.service.mail-integration-service](cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a)). A host app and its command-line tool both build their client through it, so the deadline, the no-retry rule, the empty-reply check and the failure wording live in one place whatever the IPC mechanism is. The host supplies the IPC round trip and an error classifier; the transport supplies the rules around them.

It declares one public error type, `MailTransportFailure` (`timedOut`, `connectionDropped`, `unreachable(String)`), which the host maps its own IPC errors onto. Every failure surfaces to the caller as `MailClientError.remote(String)`, an error type of the mail-rpc recipe.

## Behavioral Requirements

- **call-timeout-constant**: `MailDaemonTransport.callTimeout` MUST be 360 seconds, a `TimeInterval`.
- **timeout-for-sync-now**: `timeout(for:)` MUST return nil (no deadline) when the request bytes decode as a `MailRequest.syncNow`, whatever its `account` value, including nil for every account.
- **timeout-for-other-requests**: `timeout(for:)` MUST return `callTimeout` when the bytes decode as any `MailRequest` other than `syncNow`.
- **timeout-for-undecodable-bytes**: `timeout(for:)` MUST return `callTimeout` when the bytes do not decode as a `MailRequest`; the decode failure MUST NOT be raised.
- **send-passes-deadline**: `send` MUST invoke `call` with the request bytes unchanged and the value `timeout(for:)` returns for those bytes.
- **send-calls-once**: `send` MUST invoke `call` exactly once per invocation and MUST NOT retry after a failure. `call` MUST NOT retry either (the rationale is in Design Decisions).
- **send-reports-failure-first**: When `call` throws, `send` MUST pass the thrown error to `onFailure` before it throws.
- **send-classifies-failure**: When `call` throws, `send` MUST pass the thrown error to `classify` and MUST throw `remoteError(for:daemonName:)` of the classification.
- **send-empty-reply**: When `call` returns zero bytes, `send` MUST throw `MailClientError.remote` with the text `<daemonName> dropped the reply`.
- **send-returns-reply**: When `call` returns one or more bytes, `send` MUST return them unchanged. The transport does not decode or validate them; decoding belongs to `MailClient`.
- **error-timed-out**: `remoteError` for `timedOut` MUST return `MailClientError.remote` with the text `<daemonName> did not answer within 360 s`, the 360 coming from `Int(callTimeout)`.
- **error-connection-dropped**: `remoteError` for `connectionDropped` MUST return `MailClientError.remote` with the text `cannot reach <daemonName>: the connection was refused or dropped (is <daemonName> running, and signed by the same team as this tool?)`.
- **error-unreachable**: `remoteError` for `unreachable(detail)` MUST return `MailClientError.remote` with the text `cannot reach <daemonName>: <detail>`.
- **make-client-wraps-send**: `makeClient` MUST return a `MailClient` whose transport closure forwards each request to `send` with the given `daemonName`, `call`, `classify` and `onFailure`.
- **on-failure-default**: `onFailure` MAY be omitted; its default does nothing.
- **sendable-callbacks**: `call`, `classify` and `onFailure` MUST be safe to invoke from any thread (`@Sendable` in Swift).
- **failure-equatable**: `MailTransportFailure` MUST be `Error`, `Equatable` and `Sendable`.
- **no-state**: The type MUST hold no mutable state: the only stored value is the `callTimeout` constant, so concurrent calls cannot interfere inside the transport. Concurrency of the underlying calls is the host's `call` closure's concern.

### Runtime shape of one call

Request bytes (JSON of a `MailRequest`) go in, reply bytes (JSON of a `MailResponse`) come out. Outcomes: reply returned; `MailClientError.remote` for a failed call; `MailClientError.remote` for an empty reply. No other error type leaves `send`.

## Appearance

Not applicable — this is a transport rule set for a daemon client, not a visual component.

## States

Not applicable — this is a stateless transport helper, not a visual component. Its only runtime flow is a single request/reply round trip described under Behavioral Requirements.

## Accessibility

Not applicable — this is a transport rule set with no user interface, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| mail-daemon-transport-001 | call-timeout-constant, error-timed-out | `remoteError(for: .timedOut, daemonName: "d")` (test `aTimeoutSaysTheDaemonDidNotAnswerInTime`) | `MailClientError.remote("d did not answer within 360 s")`; `callTimeout == 360` |
| mail-daemon-transport-002 | timeout-for-sync-now | `timeout(for:)` of encoded `.syncNow(account: nil)` and of `.syncNow(account: "a@example.com")` (test `onlySyncNowWaitsWithoutADeadline`) | nil in both cases |
| mail-daemon-transport-003 | timeout-for-other-requests | `timeout(for:)` of encoded `.signIn` and of `.listAccounts` (test `onlySyncNowWaitsWithoutADeadline`) | 360 in both cases |
| mail-daemon-transport-004 | timeout-for-undecodable-bytes | `timeout(for: Data("not a request".utf8))` (test `onlySyncNowWaitsWithoutADeadline`) | 360, nothing thrown |
| mail-daemon-transport-005 | error-connection-dropped | `remoteError(for: .connectionDropped, daemonName: "d")` (test `aRefusedConnectionSaysTheDaemonCannotBeReached`) | `MailClientError.remote("cannot reach d: the connection was refused or dropped (is d running, and signed by the same team as this tool?)")` |
| mail-daemon-transport-006 | error-unreachable | `remoteError(for: .unreachable("nope"), daemonName: "d")` (test `everyOtherFailureSaysTheDaemonCannotBeReached`) | `MailClientError.remote("cannot reach d: nope")` |
| mail-daemon-transport-007 | send-calls-once, send-reports-failure-first, send-classifies-failure | `send` with a `call` that counts and throws, `classify` returning `.timedOut`, `onFailure` that counts (test `aFailedCallIsClassifiedReportedAndNotRetried`) | throws `MailClientError.remote("d did not answer within 360 s")`; `call` ran 1 time; `onFailure` ran 1 time |
| mail-daemon-transport-008 | send-empty-reply | `send` with a `call` returning `Data()` (test `anEmptyReplyIsAnError`) | throws `MailClientError.remote("d dropped the reply")` |
| mail-daemon-transport-009 | send-returns-reply, send-passes-deadline | `send` of the encoded `.syncNow(account: nil)` with a `call` that records its deadline and returns `Data("ok".utf8)` (derived from the source; no test asserts it) | returns `Data("ok".utf8)`; the recorded deadline is nil |
| mail-daemon-transport-010 | make-client-wraps-send, on-failure-default | `makeClient` with a `call` that throws and a `classify` returning `.unreachable("x")`, no `onFailure`; then `MailClient.providerStatus()` (derived from the source; no test asserts it) | throws `MailClientError.remote("cannot reach d: x")`, nothing else happens |

## Edge Cases

- **Empty request bytes**: `timeout(for:)` MUST return `callTimeout` because empty bytes do not decode as a `MailRequest`.
- **Empty reply**: A zero-byte reply MUST become `<daemonName> dropped the reply`, not an empty successful result.
- **Reply that is not a valid response**: `send` MUST return the bytes without checking them; the decode failure arises later in `MailClient.send`, outside this type.
- **Failure after a deadline**: The transport does not enforce the 360 s deadline itself; it hands the value to `call`, and the host's IPC layer enforces it and reports expiry through `classify` as `timedOut`.
- **Long sync with healthy daemon**: `syncNow` MUST NOT be given a deadline, because it answers when the whole sync ends, joins a sync already running, and is paced at about 40 messages a second per the source comment.
- **Dead daemon during a sync**: With no deadline, the call ends through the dropped connection, which the host classifies as `connectionDropped`.
- **Empty daemon name**: Not validated; the name is interpolated as given into every sentence.
- **Empty or unusual `unreachable` detail**: Interpolated as given; an empty detail yields `cannot reach <daemonName>: `.
- **Cancellation**: No cancellation handling in the source; a `CancellationError` thrown by `call` goes through `onFailure` and `classify` like any other error, and the host's `classify` decides what it becomes.
- **Concurrent calls**: The transport holds no state, so concurrent `send` calls run independently; ordering and serialisation are the host's `call` closure's concern.
- **Offline or daemon not running**: Surfaces as `connectionDropped` or `unreachable` once classified, and then as the sentence above. There is no queueing and no retry.
- **Retry after failure**: Never. A repeated attempt is the caller's decision.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `daemonName` | `String` | none, required | What failure sentences call the daemon (the source's example is `temporald`). |
| `call` | `@Sendable (Data, TimeInterval?) async throws -> Data` | none, required | One IPC round trip, waiting at most the given time (nil: no deadline). It must not retry. |
| `classify` | `@Sendable (any Error) -> MailTransportFailure` | none, required | Maps the host's IPC error onto a `MailTransportFailure`. |
| `onFailure` | `@Sendable (any Error) -> Void` | does nothing | Sees the underlying error before it becomes a sentence. |
| `callTimeout` | `TimeInterval` constant | 360 | Deadline for every request except `syncNow`. Not configurable by the caller. |

## Deep Linking

Not applicable: the type exposes no URL or navigation entry point; it only wraps a request/reply call.

## Localization

The failure sentences are hardcoded English in `remoteError` and `send` and are not externalised; a host that localizes would have to replace them.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none (inline) | `<daemonName> did not answer within 360 s` | `timedOut` |
| none (inline) | `cannot reach <daemonName>: the connection was refused or dropped (is <daemonName> running, and signed by the same team as this tool?)` | `connectionDropped` |
| none (inline) | `cannot reach <daemonName>: <detail>` | `unreachable` |
| none (inline) | `<daemonName> dropped the reply` | empty reply in `send` |

## Accessibility Options

Not applicable: the type has no visual output, motion or colour, so no display option applies.

## Feature Flags

Not applicable: the source reads no flag or setting; behavior varies only by the request and the supplied closures.

## Analytics

Not applicable: the source emits no events. The `onFailure` hook is a caller-supplied callback, not analytics.

## Privacy

- **Data collected**: None by this type. It forwards request bytes, which can carry mail account names and, for `importOAuthClient`, OAuth client JSON, and reply bytes, which can carry mail content.
- **Storage**: None; nothing is written or cached.
- **Transmission**: Bytes go only to the host's `call` closure, which owns the IPC channel to the daemon.
- **Retention**: None.
- **Error text**: The `unreachable` detail and the underlying error passed to `onFailure` come from the host and are shown or handled as the host decides.

## Logging

Not applicable: the source makes no log call. The `onFailure` closure is the hook where a host may log the underlying error.

## Platform Notes

- **SwiftUI**: The Swift source uses `Foundation` only, async/await, `@Sendable` closures (`makeClient` stores them as `@escaping`, `send` takes them non-escaping), `JSONDecoder` for the request peek, and `LocalizedError` through `MailClientError`. A SwiftUI host reads the failure sentence from `localizedDescription` for its Integrations panel.
- **Compose**: Kotlin has no direct equivalent type; use an `object` with suspend functions, `kotlinx.serialization` to peek at the request kind, a sealed class for `MailTransportFailure`, and `withTimeoutOrNull` only if the host's IPC does not enforce the deadline itself (the Swift transport only passes the deadline to `call`). Keep the no-retry rule and exact sentences.
- **React/Web**: Use a module of async functions, `JSON.parse` to peek at the request kind, the host's `call` enforcing the deadline it is given (as in Swift, the transport only passes it on; an `AbortController` with `setTimeout` belongs in that `call`, and none for `syncNow`), and an `Error` subclass carrying the sentence. Do not retry on `fetch` failures.
- **AppKit / UIKit**: A macOS host maps its XPC client errors (the source comment names a timeout, a dropped connection and anything else) onto `MailTransportFailure` in `classify`. The "signed by the same team" hint in the connection-dropped sentence points at a code-signing mismatch between the daemon and the tool, the usual reason an XPC connection is refused.
- **WinUI 3**: Write a static class `MailDaemonTransport` in C#. Use `Task<byte[]>` with a `Func<byte[], TimeSpan?, Task<byte[]>>` for `call`, whose host implementation owns the `CancellationTokenSource.CancelAfter(deadline)` and skips it when the deadline is null (the transport only passes the deadline on, as in Swift), `System.Text.Json` (`JsonDocument`, try-catch on `JsonException`) to peek at the request kind, a sealed record hierarchy or enum for `MailTransportFailure`, and a custom `MailClientException` for `MailClientError`. Map `TimeoutException` or `OperationCanceledException` from a named-pipe or `HttpClient` call onto `timedOut`, `IOException` and `HttpRequestException` onto `connectionDropped` or `unreachable`. Callbacks are plain `Func`/`Action`; there is no `Sendable` marker, so document thread safety instead. There is no code-signing hint on Windows; change that sentence to fit the IPC in use.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Integrations/Service/MailDaemonTransport.swift` | unverified |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: `syncNow` has no deadline while every other request, and bytes that are not a request, keep `callTimeout`.
**Rationale**: A sync answers when it ends, joins one already running, and is paced at about 40 messages a second, so a large first sync can outlast any fixed deadline while the daemon is healthy. A dead daemon still ends the call through the dropped connection.
**Approved**: pending

**Decision**: `callTimeout` is 360 s.
**Rationale**: It must exceed the SDK's 300 s cap on a browser sign-in, which runs inside the daemon while the call waits.
**Approved**: pending

**Decision**: Nothing is retried.
**Rationale**: `signIn` opens a browser and `modifyLabels` writes to Gmail; a retry after a timeout could do either twice.
**Approved**: pending

**Decision**: An empty reply is an error, `<daemonName> dropped the reply`.
**Rationale**: Zero bytes cannot be a `MailResponse`; reporting it here gives the same wording to every host rather than a decode error later.
**Approved**: pending

**Decision**: The host classifies its own IPC errors into `MailTransportFailure`, and `onFailure` sees the raw error first.
**Rationale**: The wording stays in one place whatever the transport is, while the host keeps the underlying error for its own logs.
**Approved**: pending

**Decision**: Failure sentences are hardcoded English with the daemon name interpolated.
**Rationale**: Both the host's panel and its command-line tool show the same sentence; the source does not externalise it. A port that needs localization must replace them.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.access-patterns.timeout-configuration](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dc15eb62-a72c-5b09-b9e7-c1bed983f499) | passed | access-patterns |
| [adc.check.access-patterns.retry-with-backoff](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bcb17bfe-d2d6-53f3-b2af-06b7eea3da61) | passed | access-patterns |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | internationalization |

The type does one job (rules around an IPC call) and leaves IPC, decoding and presentation to the host and to `MailClient`, so separation of concerns passes. The test file covers the timeout rules, the failure sentences, the empty reply and the failure path of `send`, but no test asserts `send-returns-reply`, `send-passes-deadline`, `make-client-wraps-send` or `on-failure-default` (vectors 009 and 010), so coverage is partial. Timeouts are explicit and named. Retry is deliberately absent (the `send-calls-once` requirement), so that check passes: there is no backoff because a retry could repeat a browser sign-in or a Gmail write. The failure sentences are inline English, so the hardcoded-strings check fails.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
