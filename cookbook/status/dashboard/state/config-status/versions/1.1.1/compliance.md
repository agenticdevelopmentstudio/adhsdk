
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.performance.caching-strategy](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/3b773606-ab90-5e7d-8e96-093777dcf070) | passed | performance |

The hook separates fetching (two private query hooks), classification (the engine plus the app's paused fold in `lib/config-status`) and model assembly (the pure `buildStatus`), and keeps the roster query private so there is one access point. Unit coverage exists in `use-config-status.dom.test.tsx` for the scan-failure and both-loaded paths, but not for `enabled: false`, `refetch`, `invalidateConfigQueries`, the paused fold through this hook, or the per-platform tally, hence partial. Error handling is explicit for a single failure, but when both queries fail only the roster error is returned, and a malformed classification body is cast rather than validated and throws during render, hence partial. Caching uses shared react-query keys, a joint invalidation helper, and the server's 30-second cache instead of a polling interval.

