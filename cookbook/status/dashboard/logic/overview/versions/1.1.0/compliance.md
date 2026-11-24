
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | reliability |

**Separation of concerns.** The module holds only presentation projections; derivation stays on the server and row construction in a separate module.

**Unit test coverage.** The module's own test suite covers the real-environment predicate and the window caption, and a parity test suite covers the problems-to-indicator operation and the wire-indicator translation map. The deploy-counts operation and the headline operation have no direct tests.

**Explicit error handling.** Nothing throws, but unparseable timestamps are not guarded: an unparseable time stamp is counted inside the window and an invalid bound yields a `"NaNh"` caption.

**Data integrity.** The indicator rule is pinned to the server by a parity test, but the real-environment predicate exists as two unpinned copies (web and server) despite a doc comment promising they cannot disagree.

