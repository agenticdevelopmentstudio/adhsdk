
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | passed | Reliability |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | Reliability |

Notes: separation-of-concerns passes because `ProjectReconciler.swift` does
exactly one thing — match scan results against known rows — and delegates
walking the filesystem to `GitRepoScanner`, persisting rows to
`ProjectDatabase`, and presenting progress to `ProjectsCoordinator` and its
progress window, none of which leaks into this file. unit-test-coverage is
partial: `ProjectReconcilerTests.swift` exercises every branch of `plan(...)`
directly (inserts, unchanged, remote updates, remote-based moves,
name-based moves, ambiguous moves, move-before-insert ordering, deletes, and
the summary counts) and `uniqueName(forPath:taken:)`'s escalation directly,
but `repositoryExists(atPath:)` is only ever exercised incidentally, as the
default `isStillARepository` argument hitting the real filesystem at
ephemeral test paths, never by a dedicated test asserting its true/false
contract against a constructed `.git` entry, and `uniqueName`'s
exhausted-fallback branch has no test at all. idempotent-operations
passes: the doc comment and `testAnUnchangedRepoProducesNoWrite`'s own name
tie the exact-path pass's "no update when nothing changed" behavior directly
to re-running a scan over an unchanged tree producing no database write.
data-integrity is partial because of the pending decision on
duplicate-scanned-path-handling: overlapping scan roots can report one
directory twice and silently produce two rows for it, with nothing in this
file detecting it. Duplicate `existing` rows are excluded by the `git_repo`
table's `UNIQUE` path constraint rather than by this file.

