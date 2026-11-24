
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.best-practices.good-test-properties](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9144e220-ad70-51db-ba81-cdb0cc1b66c8) | passed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |

`uptime.ts` is pure arithmetic with no I/O, rendering or state, separated from the hook that fetches the data and the component that displays it, so separation-of-concerns passes. `uptime.test.ts` covers every exported function, including the null paths and each `dayStatus` branch, with small independent Vitest cases, so unit-test-coverage and good-test-properties pass. explicit-error-handling is partial: "no data" is signalled explicitly with `null`, but inconsistent or `NaN` counts pass through unvalidated and surface as out-of-range or `NaN` percentages rather than being rejected; the boundary cases (exactly half down, zero total with down checks, negative total) are not in the test suite.

