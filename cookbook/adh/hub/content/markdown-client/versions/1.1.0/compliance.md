
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.reliability.error-recovery](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/694a971d-282d-501b-8861-c4ece3b01edd) | partial | reliability |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | reliability |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | partial | reliability |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | partial | access-patterns |
| [adc.check.access-patterns.pagination-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/e29ce31a-67cb-5690-b2ca-b1065ccdaf1a) | failed | access-patterns |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | internationalization |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | privacy-and-data |

**separation-of-concerns**: passed. Each of the three domains — research
documents, legacy bucket/schema definitions, and taxonomy writes — is its
own module with its own route constants and its own exported API object,
and wire.ts isolates every backend shape from all three. The one crossing
point, `markdownApi.createCategory` posting to the markdown surface instead
of the generic taxonomy door, is deliberate and documented in taxonomy.ts's
own header comment.

**unit-test-coverage**: partial. markdown.test.ts covers the three pure
fallback helpers (`withTags`, `categoryNodes`, `tagNodes`) and two cases of
`markdownApi.routeAvailable`, but none of `markdownApi`'s other eleven
operations, and schemas.ts and taxonomy.ts have no test file at all.

**explicit-error-handling**: partial. `markdownApi.publish` and
`.createCategory` each catch a 409 and rethrow a friendly message, and
`schemasApi.create` does the same for the parent bucket; every other
markdown.ts/taxonomy.ts operation lets its error propagate unmodified.
`schemasApi.get`, by contrast, catches every error indiscriminately and
discards it — the schemas-get-swallows-errors requirement.

**error-recovery**: partial. `schemasApi.create` has an explicit
compensating rollback (delete every table it created, then the parent
bucket) if a child-table insert fails partway, stating its own goal is
avoiding an orphaned half-built schema. `schemasApi.update`'s table-reconcile
loop has no equivalent path — the schemas-update-reconcile-has-no-rollback-or-lock requirement.

**data-integrity**: partial. `assertUniqueTableNames` stops a caller from
creating or renaming into a client-side duplicate before any request is
sent, and `update`'s delete-before-add ordering is explicitly sequenced to
avoid racing the backend's unique index. The same operation's reconcile can
still leave a schema with a half-applied set of tables if one request in
the sequence fails, with nothing to detect or repair it — the
schemas-update-reconcile-has-no-rollback-or-lock requirement.

**idempotent-operations**: partial. `removeCategoryParent`, `deleteCategory`,
and `deleteTag` are each documented as safe to call twice, and
`createCategory` re-posting an existing name is documented as idempotent
when every requested parent is already one of its parents. Create/update/
delete on `markdownApi` and `schemasApi` are ordinary POST/PUT/DELETE with
no such guarantee, and `schemasApi.update`'s reconcile step is the one
operation this package documents no idempotency story for at all.

**error-response-handling**: partial. Three call sites (`markdownApi.publish`,
`markdownApi.createCategory`, `schemasApi.create`) map a 409 to a message a
form can show directly; every other call — including taxonomy.ts's own
documented 409/400 cases on `addCategoryParent` — surfaces the raw thrown
error to its caller with no client-side translation.

**pagination-support**: failed. `markdownApi.list` has no cursor or page
parameter — it always requests the fixed 200-row page — and
`schemasApi.list`/`.get` fetch every bucket and bucket-type row with no
filter at all, relying on the generic CRUD endpoint's own roughly 500-row
cap; a workspace or ecosystem past either limit silently loses rows with no
signal that more exist.

**no-hardcoded-strings**: failed. Every user-facing error message this
package produces — the route-conflict message, the category-conflict
message, the duplicate-table-name message, and the bucket-conflict message
— is a hardcoded English literal with no localization hook.

**data-minimization**: passed. None of the four files persist anything
client-side or add fields beyond what each backend route already expects;
every request body sent is exactly the caller-supplied input, or its
`compact()`-filtered subset for a PUT, and no telemetry, analytics, or
logging call reads any of it.

