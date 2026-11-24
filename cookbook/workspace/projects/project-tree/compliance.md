
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.good-test-properties](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9144e220-ad70-51db-ba81-cdb0cc1b66c8) | passed | Best Practices |

Notes: separation-of-concerns passes because `ProjectTree.swift` builds and
sorts an in-memory node graph only — no `NSOutlineView`, no `NSView`, and no
persistence or network code — leaving the tree's rendering entirely to
`ProjectBrowserViewController` and the `GitRepo` data shape to `GitRepo.swift`.
unit-test-coverage is partial because `ProjectTreeTests.swift` exercises
home-relative truncation, the outside-home leading slash, folder-before-project
sorting, registry-sourced naming, distinct-path folders, display order, and
the empty-input case (PT-001 through PT-008), but has no test for a duplicate
leaf path (PT-009) or for the folder/project path collision this recipe flags
as `project-tree-leaf-path-collision` (PT-010) — both are traced to the
source's control flow rather than to an assertion in the given suite.
good-test-properties passes because every test in `ProjectTreeTests.swift` is
a synchronous, `@MainActor`-isolated `XCTAssertEqual`/`XCTAssertTrue` call
against a locally constructed `[GitRepo]` array and a fixed `home` URL, with
no shared fixture, no I/O, and no ordering dependency between tests.

