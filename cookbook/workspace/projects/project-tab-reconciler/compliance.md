
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | passed | Reliability |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | Reliability |

Notes: separation-of-concerns passes because `ProjectTabReconciler.swift`
does exactly one thing — decide keep/add/drop from given state — and
delegates walking the filesystem to the injected `existsOnDisk` closure,
persisting the result to `ProjectDatabase`, and presenting the reconciled
window to `ProjectController`, none of which leaks into this file.
unit-test-coverage is partial: `ProjectTabReconcilerTests.swift` exercises
`plan(...)`'s add/keep/drop branches, the mounted-versus-unmounted boundary,
the symlink-resolution case, and both `makeRecords` invariants directly, but
`arrangement(of:activeTabID:)` has no dedicated test in this file at all,
and no test exercises the real, non-overridden
`volumeIsMounted(for:projectDirectory:)` against an actual resource-value
failure. explicit-error-handling is partial because of the pending decision on
volume-lookup-failure-handling: `volumeURL(of:)`'s `try?` turns a thrown
resource-value error into the same `nil` that a legitimately absent volume
URL produces, and that ambiguity feeds directly into a permanent-deletion
decision. idempotent-operations passes: every function in this file is a
pure, synchronous computation over its arguments with no stored state, so
calling `plan(...)` again with the same stored tabs, checkouts, and
filesystem state MUST reproduce the same `Plan` (see
`reconciler-no-mutation-of-inputs`, `reconciler-synchronous-non-throwing`).
data-integrity is partial: the pending decision on
volume-lookup-failure-handling can permanently drop a record whose mount
status was never established, while duplicate checkout directories rest on
the caller precondition in **duplicate-checkout-directory-handling**.

