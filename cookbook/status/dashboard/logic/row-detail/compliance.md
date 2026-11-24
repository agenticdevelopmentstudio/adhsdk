
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.best-practices.good-test-properties](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9144e220-ad70-51db-ba81-cdb0cc1b66c8) | passed | best-practices |

**Separation of concerns.** The module only maps a `Row` to display fields and serializes them. Platform labels come from `deploy-display.ts`, host parsing comes from `url.ts`, and rendering and the clipboard write belong to the calling components.

**Unit test coverage.** `row-detail.test.ts` exercises both exports: the deploy and endpoint mappings, resolved rows, problem de-duplication, the diagnostics, the `since` fallback, error text, every settled and unsettled deploy outcome including the Crunchy carve-out, and the serializer's populated-only, link and error-block behavior. The GlitchTip carve-out, the `url` line and the empty-string fallbacks are not asserted directly.

**Explicit error handling.** The only failure path is URL parsing inside `hostOf`, which falls back to the raw input by design. Every other input maps to a defined value.

**Good test properties.** The tests build rows from one `row()` helper with explicit overrides, assert observable fields, and depend on no clock, network or shared state.

