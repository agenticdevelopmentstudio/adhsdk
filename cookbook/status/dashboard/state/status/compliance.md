
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.performance.caching-strategy](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/3b773606-ab90-5e7d-8e96-093777dcf070) | passed | performance |

The hook owns only the query definition and error-reason extraction; transport and base path belong to `StatusApiClient`, and rendering belongs to `Dashboard`. `use-status.dom.test.tsx` beside the hook covers every conformance vector (use-status-001 to 014) against the real hook with a stubbed `fetch`, including the error-detail extraction and the `status <code>` fallback, hence passed. Every failure path produces a thrown `Error` that reaches the UI, but a non-string `error` detail is coerced to an unhelpful message and a malformed success body is cast rather than validated, hence partial. Caching uses a single shared react-query key with refetch-on-focus and defers periodic refresh to the app-wide `useRefreshAll` interval.

