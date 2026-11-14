
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.security.server-side-authorization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/90e085e3-5112-5c02-9c10-4a2e324eeca1) | passed | Security |
| [adc.check.security.secure-transport](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0a75f61f-9508-506e-b92e-0f5b29a91c95) | partial | Security |
| [adc.check.access-patterns.reconnection-strategy](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9200a653-2bfd-5ea2-adbe-758243dc9228) | partial | Access Patterns |
| [adc.check.access-patterns.pagination-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/e29ce31a-67cb-5690-b2ca-b1065ccdaf1a) | partial | Access Patterns |
| [adc.check.access-patterns.offline-behavior](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/df7f401a-39be-5c60-bab4-85dd95bd1ab1) | partial | Access Patterns |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | passed | Access Patterns |
| [adc.check.access-patterns.retry-with-backoff](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bcb17bfe-d2d6-53f3-b2af-06b7eea3da61) | failed | Access Patterns |
| [adc.check.access-patterns.timeout-configuration](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dc15eb62-a72c-5b09-b9e7-c1bed983f499) | failed | Access Patterns |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | passed | Reliability |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | Reliability |

`separation-of-concerns` passes: both files contain zero JSX or DOM code — they export hooks and
plain functions consumed by a separate presentation layer. `unit-test-coverage` fails: this
checkout has no test file next to either `use-dms.ts` or `use-notifications.ts`, and the one
messaging-adjacent test found (`MessagingPane.test.tsx`, in a different package) exercises a
different component and neither imports nor mocks either file. `explicit-error-handling` is
`partial`: every plain HTTP failure either throws (`AuthHttpError`/`Error`) or lands in an exposed
`error` field, but several catches (`fetchPresenceMap`, the SSE malformed-frame handler, and both
poll-fallback refetches) discard the error with no signal at all beyond a silent fallback.
`server-side-authorization` passes: `startDm`'s `403`-to-`forbidden` mapping and every route's
participant-scoping are enforced entirely by the backend per the source's own "Backend contract"
comments; neither file performs a client-side permission check. `secure-transport` is `partial`:
neither file controls TLS itself (deployment-level, unverifiable from this checkout), and the
SSE-token-in-query-string design is a documented deviation from the header-based scheme the rest of
this recipe uses, per `sse-token-rides-the-query-string`. `reconnection-strategy` is `partial`:
`connectSse` defines explicit, self-healing reconnection (live retry plus interval-and-focus poll),
but with no exponential backoff or jitter — a fixed poll interval only. `pagination-support` is
`partial`: the DM conversation list and the notification inbox both support pagination
(`pageSize`/`page`, and the DM list's growing-window `loadMore`), but the DM thread exposes no
further-back paging for message history. `offline-behavior` is `partial`: the poll fallback
degrades gracefully across a connectivity blip, but neither file checks `navigator.onLine` or
queues a `send`/mutation issued while offline. `error-response-handling` passes: every documented
status this recipe's own backend-contract comments describe (`401`, `403`, `204` where relevant) is
handled explicitly, and every other non-2xx status surfaces as a typed `AuthHttpError`.
`retry-with-backoff` fails: no call in either file retries a failure with backoff of any kind
beyond the single inherited `401` refresh-and-retry. `timeout-configuration` fails: no call sets a
deadline or `AbortSignal`. `idempotent-operations` passes: `mergeMessage`'s id-based dedupe makes a
duplicate delivery (the SSE stream and a `send`'s own POST response both resolving the same row) a
no-op, and `send` generates a `clientMessageId` intended for server-side idempotency per the
source's own comment. `graceful-degradation` passes: a dead SSE stream downgrades to polling, a
failed presence fetch downgrades to "assume offline," and a failed list refresh keeps the last good
data — none of the three crashes the hook or blanks the UI.

