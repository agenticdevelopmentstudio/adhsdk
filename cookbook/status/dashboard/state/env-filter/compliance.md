
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | reliability |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | privacy-and-data |

The hook holds only selection state and persistence; the filtering of rows by environment lives in `OverviewTab`, so logic and presentation are separated. No test exercises `useEnvFilter` directly; the only coverage is `retired-storage.test.ts`, which asserts the `"adh-env-filter"` key survives the retired-storage purge, so hydration filtering and toggle persistence are untested. Both storage failures are caught and discarded without a log or signal. That is deliberate and commented in the source, but it falls short of the "MUST NOT be silently swallowed" bar, hence partial. When storage is unavailable the hook degrades to an in-memory filter that still works. Only environment names are stored, and nothing leaves the device.

