
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.access-patterns.api-design-conventions](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b6745c95-4ef2-5ab4-8791-00ffc1d7b82d) | passed | access-patterns |
| [adc.check.access-patterns.pagination-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/e29ce31a-67cb-5690-b2ca-b1065ccdaf1a) | passed | access-patterns |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | passed | reliability |
| [adc.check.reliability.error-recovery](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/694a971d-282d-501b-8861-c4ece3b01edd) | partial | reliability |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | internationalization |
| [adc.check.security.secure-transport](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0a75f61f-9508-506e-b92e-0f5b29a91c95) | passed | security |
| [adc.check.security.secure-log-output](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b258657f-bb73-5491-9c70-0d14afdfa6ce) | passed | security |

Every logic component in this cookbook is held to at least
`separation-of-concerns` and `unit-test-coverage`, and both pass here on
their own terms. **`separation-of-concerns`** passes because each of the
fourteen files owns exactly one route stem/entity family with no
cross-file reach-in beyond the small, explicit `import { toX } from
"./y"` re-mapping calls that `programs.ts`/`triage.ts`/`templates.ts`
deliberately make (e.g. `toProject` reused by `programs.projects()`).
**`unit-test-coverage`** passes because four real `*.test.ts` files
(`projects.test.ts`, `search.test.ts`, `live.test.ts`,
`programs-milestones-health.test.ts`) exercise the wire contract, the
mappers, `compareRank`, `threadOf`, `milestoneProgress`, and the live-wake
refcounting/coalescing/poll-fallback/unsubscribe-race behavior directly —
the Conformance Test Vectors above are drawn from those real assertions,
not invented. **`api-design-conventions`** passes: every client follows one
`toX`/`BASE`/CRUD-object shape, and PATCH bodies uniformly use `compact` for
undefined-vs-null semantics. **`pagination-support`** passes: three
distinct, well-documented pagination strategies coexist correctly for their
different needs (activity's newest-first opaque composite keyset, triage/
search's clamped-limit-with-`hasMore` pages, and iteration/program/board
lists' unpaginated-but-reach-filtered full lists). **`idempotent-operations`**
passes: `artifacts.link` (per `(direction,kind,id)`) and `triage.accept`
(stamp preserved) are both explicitly, deliberately idempotent, each with a
doc comment and a dedicated behavior. **`error-recovery`** is `partial`: a
404 on `get()` recovers to a documented `null` and a search/triage/artifacts
list recovers to an empty result shape, but there is no retry or backoff
anywhere in this domain — a single network failure on any write (a `create`,
a `move`, an `accept`) surfaces immediately as a thrown error with no
built-in retry, which is a fact about the current source (see Edge Cases:
Error states), not a marker-worthy gap, since no doc comment or type
signature in this domain promises retry behavior it fails to deliver.
**`no-hardcoded-strings`** is `failed`, honestly: `validateKeyPrefix`'s two
messages and the two default item nouns are fixed English literals with no
i18n key anywhere in these fourteen files (see Localization) — a real,
reported gap in this vocabulary, not a marker, because it is a plain,
observable fact about the source rather than an unresolvable contract
question. **`secure-transport`** passes: every call goes through
`authedJson`/`authedRequest`'s Bearer-token client, and this domain attaches
no credential or cookie of its own. **`secure-log-output`** passes because
there is no logging at all in this domain (see Logging) — nothing here can
leak a secret into a log it never writes to.

