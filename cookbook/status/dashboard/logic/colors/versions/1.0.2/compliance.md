
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |

**Separation of concerns.** The module holds only color data and two pure helpers, with no React, DOM or I/O; components apply the values and the theme package owns the token values.

**Unit test coverage.** There is no `colors.test.ts`, and no test asserts `envColor`, `envBadgeLabel` or the table contents; `row-model.test.ts` covers only `row-model`'s own tone colors.

**Explicit error handling.** `envColor` handles nullish and unknown input with an explicit fallback, and missing status keys return `undefined` for the caller to handle. The env lookups do not restrict themselves to own keys, so inherited object members leak through as non-string values (see env-object-prototype-keys), and `envBadgeLabel` throws on nullish input, which its type signature forbids.

