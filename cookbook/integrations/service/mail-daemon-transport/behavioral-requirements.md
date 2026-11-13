
- **call-timeout-constant**: `MailDaemonTransport.callTimeout` MUST be 360 seconds, a `TimeInterval`. The source comment gives the reason: it is longer than the SDK's own 300 s cap on a browser sign-in, which runs inside the daemon while the call waits for its answer.
- **timeout-for-sync-now**: `timeout(for:)` MUST return nil (no deadline) when the request bytes decode as a `MailRequest.syncNow`, whatever its `account` value, including nil for every account.
- **timeout-for-other-requests**: `timeout(for:)` MUST return `callTimeout` when the bytes decode as any `MailRequest` other than `syncNow`.
- **timeout-for-undecodable-bytes**: `timeout(for:)` MUST return `callTimeout` when the bytes do not decode as a `MailRequest`; the decode failure MUST NOT be raised.
- **send-passes-deadline**: `send` MUST invoke `call` with the request bytes unchanged and the value `timeout(for:)` returns for those bytes.
- **send-calls-once**: `send` MUST invoke `call` exactly once per invocation and MUST NOT retry after a failure. The doc comment on `makeClient`'s `call` parameter states why: `signIn` opens a browser and `modifyLabels` writes to Gmail, so a retry after a timeout could do either twice.
- **send-reports-failure-first**: When `call` throws, `send` MUST pass the thrown error to `onFailure` before it throws.
- **send-classifies-failure**: When `call` throws, `send` MUST pass the thrown error to `classify` and MUST throw `remoteError(for:daemonName:)` of the classification.
- **send-empty-reply**: When `call` returns zero bytes, `send` MUST throw `MailClientError.remote` with the text `<daemonName> dropped the reply`.
- **send-returns-reply**: When `call` returns one or more bytes, `send` MUST return them unchanged. The transport does not decode or validate them; decoding belongs to `MailClient`.
- **error-timed-out**: `remoteError` for `timedOut` MUST return `MailClientError.remote` with the text `<daemonName> did not answer within 360 s`, the 360 coming from `Int(callTimeout)`.
- **error-connection-dropped**: `remoteError` for `connectionDropped` MUST return `MailClientError.remote` with the text `cannot reach <daemonName>: the connection was refused or dropped (is <daemonName> running, and signed by the same team as this tool?)`.
- **error-unreachable**: `remoteError` for `unreachable(detail)` MUST return `MailClientError.remote` with the text `cannot reach <daemonName>: <detail>`.
- **make-client-wraps-send**: `makeClient` MUST return a `MailClient` whose transport closure forwards each request to `send` with the given `daemonName`, `call`, `classify` and `onFailure`.
- **on-failure-default**: `onFailure` MAY be omitted; its default does nothing.
- **sendable-callbacks**: `call`, `classify` and `onFailure` MUST be `@Sendable`; `makeClient` stores them as `@escaping`, `send` takes them non-escaping.
- **failure-equatable**: `MailTransportFailure` MUST be `Error`, `Equatable` and `Sendable`.
- **no-state**: The type MUST hold no mutable state: the only stored value is the `callTimeout` constant, so concurrent calls cannot interfere inside the transport. Concurrency of the underlying calls is the host's `call` closure's concern.

### Runtime shape of one call

Request bytes (JSON of a `MailRequest`) go in, reply bytes (JSON of a `MailResponse`) come out. Outcomes: reply returned; `MailClientError.remote` for a failed call; `MailClientError.remote` for an empty reply. No other error type leaves `send`.

