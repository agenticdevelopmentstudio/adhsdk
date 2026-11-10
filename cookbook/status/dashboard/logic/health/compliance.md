
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.reliability.health-observability](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d4ece88d-eeff-5e3f-8823-d8c2929a35e0) | passed | reliability |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | reliability |

**Separation of concerns.** The module holds only the classification rule and its thresholds. Fetching, timing, body capping and error-message wording live in the status-server probe.

**Unit test coverage.** `health.test.ts` covers the constants, every branch of `classify` (2xx, expected-status match, non-match, health body ok, not ok, non-JSON and unknown shape, marker present, missing and absent) and the latency threshold on both sides.

**Explicit error handling.** Partial. The `JSON.parse` failure is caught and deliberately discarded with a documented comment, and the caller always receives a verdict. There is no signal to tell "body was HTML" apart from "body was healthy".

**Health observability.** The module defines the three-valued verdict the dashboard shows for every endpoint, and it separates slow (degraded) from broken (down).

**Data integrity.** Partial. The numeric inputs are not validated, so a `NaN` latency classifies as healthy. The web copy is also kept identical to the server copy only by convention, with no parity test.

