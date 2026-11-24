
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

