
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.best-practices.good-test-properties](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9144e220-ad70-51db-ba81-cdb0cc1b66c8) | passed | best-practices |
| [adc.check.internationalization.locale-aware-formatting](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c87ff1f1-9d77-5167-b0c4-f13f2aae5acb) | partial | internationalization |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | internationalization |

**Separation of Concerns**: The functions only word values; the derivation lives in the status server and the rendering in the pages and charts, so the module has one reason to change.

**Unit Test Coverage**: `dashboard-format.test.ts` has a test for each of vectors dfmt-001 to dfmt-022, covering every exported function, the 1000 boundary, rounding to 1000, invalid timestamps, an unknown range, the whole-list re-sort, the inherited-name guard and the absent-views path.

**Good Test Properties**: The tests are deterministic, use fixed timestamps and one table-driven case, and do not depend on the viewer's zone because the code and the expected values are both UTC.

**Locale Aware Formatting**: Dates use `Intl` rather than hand-built strings, but the locale and zone are fixed to English and UTC on purpose, and the with-site sort follows the runtime's default locale, so formatting is consistent rather than locale-aware.

**String Externalization**: The ` UTC`, ` (UTC)`, `ms` and `s` literals and the English month names are hardcoded in the module and not routed through a string table.

