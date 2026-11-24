
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | failed | best-practices |
| [adc.check.performance.caching-strategy](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/3b773606-ab90-5e7d-8e96-093777dcf070) | passed | performance |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | partial | reliability |
| [adc.check.privacy-and-data.secure-data-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9d865cfa-ff98-5b90-b5da-58a611d3535b) | partial | privacy-and-data |

The hook depends only on the source and cache ports; transport, persistence and backend choice live in separate adapters composed in `telemetry/client.ts`. `parseSnapshot` has direct unit tests in `local-cache.test.ts` (null, empty, malformed JSON, wrong shapes, round trip), but the hook itself, `liveSource` and the `localCache` I/O wrapper have none, hence partial. Error handling fails the check because the hook discards the query error entirely: a source that never answers looks like an empty, healthy snapshot, and storage failures are swallowed without a log. Caching is deliberate: one shared react-query key, a 60-second poll, and a persisted last-known snapshot for instant paint. Degradation is partial because stale or empty data is served during an outage without any staleness indicator. Storage is partial because error titles, culprits and permalinks sit unencrypted in `localStorage` with no expiry.

