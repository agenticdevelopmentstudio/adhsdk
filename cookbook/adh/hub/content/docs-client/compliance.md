
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | partial | Access Patterns |
| [adc.check.access-patterns.pagination-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/e29ce31a-67cb-5690-b2ca-b1065ccdaf1a) | failed | Access Patterns |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | partial | Reliability |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy and Data |

`separation-of-concerns` passes: `docs.ts` owns no HTTP call, wire-shape
knowledge, or taxonomy logic of its own — every operation is either a
direct forward to `markdownApi`/`taxonomyApi` or a one-line marker merge
(`doc-marker-on-create`, `list-scoped-to-doc-marker`). `unit-test-coverage`
fails: `docs.ts` has no test file of its own, and neither of its two
marker-merge lines is exercised by any test in the given sources; the
existing coverage in `markdown.test.ts` tests `withTags`/`categoryNodes`/
`tagNodes`, which this component depends on but does not itself invoke
under test. `error-response-handling` is partial: only `createCategory`'s
409 is mapped to a friendly message (`create-category-conflict-message`);
every other documented backend status this client's calls can receive —
403, 404, 500 — propagates unmodified with no per-status handling
(`errors-propagate-unmodified`). `pagination-support` fails: `list`
requests a fixed 200-row page with no cursor and no follow-up fetch
(`list-page-size-fixed`), so a corpus larger than 200 silently loses rows.
`idempotent-operations` is partial: `createCategory` is deliberately
idempotent when re-posting an existing name under its current parents, but
`create` is not idempotent at all (`create-not-idempotent`) and a repeated
`remove` on an already-removed id is not guaranteed to be a no-op.
`data-minimization` passes: every field sent to the backend is either
caller-supplied content/category/tags/note or the fixed `doc: true`
marker; no additional data is collected or appended.

