
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | Reliability |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | failed | Reliability |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | partial | Reliability |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | failed | Best Practices |

Notes: graceful-degradation passes because every failure path resolves to
`nil` (or, for `fetchModelInfo`, a `nil` field) rather than a thrown error or
a crash, and callers are documented to keep showing cached data.
fault-tolerance fails because, unlike the sibling `LocalModelCatalog`'s
TTL-based backoff, this file applies no cadence at all — per its own doc
comment, "every rebuild re-fetches," so a persistently down or slow server
is hit on every single caller-triggered call with no throttling; this is a
deliberate freshness-over-load-shedding tradeoff, not an oversight, but it
does not meet the reliability bar as written. idempotent-operations is
partial for the same reason as `LocalModelCatalog`: repeated successful
calls converge on the same result, but concurrent calls for the same key are
not deduplicated (`no-request-coalescing`; see
concurrent-fetch-deduplication and its Design Decision). explicit-error-handling fails because every fetch,
HTTP-status, and parse failure is discarded with zero diagnostic signal
(`fetch-error-is-fully-swallowed`).

`separation-of-concerns` passes because `LocalProviderModelStore` only fetches and caches model lists, sizes and metadata for a local provider through the shared settings store, leaving URL and size parsing to `LocalModelServer` and gating decisions to the inference guard. `unit-test-coverage` fails because no test file or test mentions `LocalProviderModelStore` under the Apple test targets, so the fetch, cache and failure paths are untested.

