
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

Notes: separation-of-concerns passes because `GitRepo.swift` holds only data
shape and trivial, filesystem-free derived accessors (`url`, `defaultName`,
`leafName`, `found`, `summaryText`); scanning the disk lives in
`GitRepoScanner`, matching found results against known rows lives in
`ProjectReconciler`, and persisting rows lives in `ProjectDatabase` — none of
that infrastructure or business logic leaks into this file. unit-test-coverage
is partial because `GitRepo.swift` has no dedicated test file of its own;
`GitRepoScannerTests.swift` exercises `ScannedGitRepo.leafName` incidentally and `ProjectReconcilerTests.swift` exercises
`ProjectScanSummary.summaryText` through two scenarios, but
`GitRepo.url`, `GitRepo.defaultName(forPath:)`, both types' `Equatable`
conformance, and the `removed`-excluded-from-`found` behavior have no test
anywhere in the given sources.

