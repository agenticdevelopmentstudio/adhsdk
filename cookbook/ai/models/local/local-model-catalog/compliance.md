
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | Reliability |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | passed | Reliability |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | partial | Reliability |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | failed | Best Practices |

Notes: graceful-degradation passes because a fetch failure never surfaces as
a thrown error or a crash — it resolves to `nil` (never known) or to stale,
previously-known sizes (`stale-while-error`), and `LocalInferenceGuard` fails
open on `nil` rather than blocking a request it cannot evaluate.
fault-tolerance passes because a persistently down or non-ollama server is
retried on the slower `failureTTL` cadence instead of being hit on every
lookup. idempotent-operations is partial because concurrent calls for the
same uncached or expired `baseURL` are not deduplicated — see the
concurrent-fetch-deduplication in Behavioral
Requirements — so repeated concurrent invocations can each trigger their own
network side effect instead of converging on one. explicit-error-handling
fails because every fetch, HTTP-status, and parse failure is discarded via
`try?` with zero diagnostic signal (`fetch-error-is-fully-swallowed`) — there
is no log, no thrown error, and no way for a caller or maintainer to
distinguish the failure modes from one another.

`separation-of-concerns` passes because `LocalModelCatalog` only caches and refreshes per-server model sizes, delegating URL derivation and size parsing to the model server helper and consuming decisions to `LocalInferenceGuard`. `unit-test-coverage` is partial: `LocalModelCatalogTests.swift` covers a single fetch served from cache, a failed fetch not retried within the failure TTL, an unlisted model having no size, and a failed refetch keeping the last known-good sizes, but nothing covers concurrent lookups, a non-loopback base URL or the swallowed error.

