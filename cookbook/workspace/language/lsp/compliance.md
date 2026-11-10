
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.reliability.error-recovery](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/694a971d-282d-501b-8861-c4ece3b01edd) | passed | Reliability |
| [adc.check.reliability.timeout-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f4d73297-4002-5b4d-91c2-74a20866ab61) | passed | Reliability |
| [adc.check.security.secure-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bb5dfc9b-c5b0-54fa-882f-007ae7dad0e9) | passed | Security |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | Security |

`separation-of-concerns` **passed**: each of the eight files owns one
concern — process/transport (`LanguageServerChannel`), one server's
lifecycle (`LanguageServerSession`), fleet reconciliation
(`LanguageServerRegistry`), per-session document forwarding
(`DocumentSyncPipeline`), workspace-scope/replay coordination
(`LanguageServerDocumentSync`), diagnostics aggregation (`DiagnosticStore`),
and configuration/settings shape (`LanguageServerConfiguration`,
`LanguageServerSettings`) — with dependencies pointing one way, from session
up through registry and document sync. `unit-test-coverage` **passed**:
every file has a dedicated test file (`DiagnosticStoreTests`,
`LanguageServerSessionTests`, `LanguageServerSessionRaceTests`,
`LanguageServerRegistryTests`, `LanguageServerDocumentSyncTests`,
`LanguageServerDocumentSyncScopeTests`,
`FakeLanguageServerSessionFidelityTests`) covering ordering, concurrency,
and failure paths, not just the happy path. `explicit-error-handling`
**passed**: every failure path surfaces a typed `LanguageServerSessionError`/`LanguageServerFailure`
or is logged with an explicit level (debug for `.notRunning`, error
otherwise) — no path silently swallows a primary operation's failure.
`error-recovery` **passed**: `start()`'s join-in-flight behavior, the
first-cause-wins failure diagnosis, and `reconcile`'s diff-and-replace
model all exist specifically to keep concurrent and transient failures from
corrupting session or registry state. `timeout-handling` **passed**: every
teardown step (abandoned-start, outstanding-request, graceful-shutdown,
exit-status) runs under an explicit wall-clock budget rather than waiting
indefinitely. `secure-storage` **passed**: per-server secrets are declared
`isSecure: true` and routed to the Keychain, never the plain settings
provider. `input-sanitization` is **partial**: workspace-scope checks
(`isInWorkspaceScope`) validate document paths against the resolved
workspace root, but `LanguageServerConfiguration.command` itself is not
validated to be an absolute path before being handed to the process spawn
(see `command-path-not-validated` above) — an accepted gap in the source,
not a hidden one.

