
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | reliability |

**Separation of concerns.** The module holds only presentation projections; derivation stays on the server and row construction in a separate module.

**Unit test coverage.** Every conformance vector has a passing test: the wire-indicator translation map, the activity-window caption, the headline operation and the still-unresolved operation, plus a purity check across the three functions.

**Explicit error handling.** Nothing throws, but invalid window bounds are not guarded: an invalid bound yields a `"NaNh"` caption.

**Data integrity.** The wire-indicator map's keys are pinned to the server's indicator union by a parity test, and no verdict is duplicated on the client.

