
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.security.server-side-authorization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/90e085e3-5112-5c02-9c10-4a2e324eeca1) | passed | Security |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | partial | Access Patterns |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | Reliability |
| [adc.check.access-patterns.pagination-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/e29ce31a-67cb-5690-b2ca-b1065ccdaf1a) | partial | Access Patterns |

`separation-of-concerns` passes: `PersonasDataSource`/`PersonasModels` hold no UI code and
`PersonasModule` holds no transport code (it depends on the injected data source); the web's
`wire.ts`/`fields.ts`/`chat-status.ts`/`canned.ts` are pure data/logic modules with, per their own
top comments, zero React or network code. `unit-test-coverage` is `partial`: `PersonasModule` is
thoroughly covered by `PersonasModuleTests.swift`, and `canned.ts`/`chat-status.ts`/
`demo-preview.ts`/`fields.ts`/`personas.ts`/`special-interests.ts` each have a matching
`__tests__/*.test.ts` file — but `persona-abilities.ts`, `persona-user-tools.ts`, and `wire.ts`
have no dedicated test file in this checkout. `server-side-authorization` passes: every grant
surface (`personaMayActApi`, `personaToolsApi`, `personaUserToolsApi`, `personaApprovalsApi`)
defers the actual authorization decision to the server and the client contains no local
permission check; `interestDocumentsApi`'s act-as-persona header is likewise checked by the
server's bucket ACL, not the client. `error-response-handling` is `partial`: `PersonasModule`
documents and tests one specific case (`HubError.notFound` on `child(for:)` becomes `.empty`),
but every other failure — on both platforms — propagates as a generic wrapped/thrown error with
no further per-status-code handling in these sources. `graceful-degradation` passes: unsupported
facets render a documented, tested notice (`FormDetails.unavailableMessage`) rather than a broken
form or a crash, and `canDemoChat`/`parseChatStatus`/`resolveChatStatus` are all documented as
never throwing on malformed input, degrading to `false`/empty/default instead. `pagination-support`
is `partial`: `api.templates` fetches one explicit, documented max-size page (`pageSize=100`),
but `interestDocumentsApi.list` sends no `limit`/`offset` at all and silently truncates any corpus
past the server's 500-row cap — a real caller of that client cannot see or page past 500 documents
with what these sources provide.

