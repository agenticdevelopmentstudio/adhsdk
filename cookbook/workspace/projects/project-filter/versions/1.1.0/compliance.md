
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.good-test-properties](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9144e220-ad70-51db-ba81-cdb0cc1b66c8) | passed | Best Practices |

Notes: separation-of-concerns passes because `ProjectFilter.swift` contains
only the substring-search and repo-matching logic — no `NSView`, no
`NSOutlineView`/`NSTableView` code, and no persistence — leaving row
construction to `ProjectBrowserViewController`/`ProjectRowView` and
`BreadcrumbPopoverViewController`, and leaving the `GitRepo` data shape to
`GitRepo.swift`. unit-test-coverage passes because
`ProjectFilterTests.swift` exercises both public functions with meaningful
assertions: anywhere-in-text matching, case-insensitivity, multiple
occurrences, an empty query on both functions, a non-matching query on both
`ranges(of:in:)` and `matches(_:query:)`, and both the name- and
path-matching branches of `matches(_:query:)` (see PF-001 through PF-009).
good-test-properties passes because every test in `ProjectFilterTests.swift`
is a synchronous, in-memory `XCTAssertEqual`/`XCTAssertTrue`/`XCTAssertFalse`
call against a locally constructed `GitRepo` or literal string, with no
shared fixture, no I/O, and no ordering dependency between tests — each is
fast, isolated, repeatable, and self-validating on its own.

