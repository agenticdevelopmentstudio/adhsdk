
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.performance.caching-strategy](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/3b773606-ab90-5e7d-8e96-093777dcf070) | passed | Performance |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | passed | Reliability |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | passed | Reliability |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy and Data |

`separation-of-concerns` **passed**: this file is pure data-layer
infrastructure — a cache client, a provider, and a subscription guard — with
no presentation code and no domain-specific fetch logic of its own; every
concrete query lives in a sibling file (see [adhsdk.ingredient.data.services.resource-data](cookbook:ec6e6ca5-8780-4ce2-8b3a-087adc50ed35) and the other data components that consume this client). `unit-test-coverage` is **passed**: `query-client.test.tsx`, `toolkit-query-provider.test.tsx` and `use-batch-run.test.tsx` assert all 23 conformance vectors, including `watchSession`'s initial subject capture, compare-then-clear guard and cross-tab `'storage'` listener (vectors 012-015) and the batch runner (vectors 017-023).
`caching-strategy` **passed**: this file is the single place that defines
the shared invalidation policy (5-minute `staleTime`, single retry, a
30-minute `gcTime` pinned by key prefix so a prefetch or a post-write
`setQueryData` survives as long as an observed read) every toolkit query
inherits, plus the whole-cache invalidation on principal change; the actual
remote fetches these policies govern are documented by the specs for the
queries that make them. `fault-tolerance` **passed**: the module tolerates
every unpredictable-state shape its own tests exercise — server vs. browser
execution, a provider nested inside another, sibling providers, no provider
at all, and a host's own differently-configured `QueryClientProvider` —
without ever throwing or adopting the wrong client. `data-integrity`
**passed**: `watchSession`'s whole-cache clear on a principal change is
exactly a corrupt-data guard — it exists specifically to stop a second
signed-in principal from reading data cached under the first, and it is a
second, independent layer against that on top of the tenant-keyed cache
segments the resource-data ingredient describes. `data-minimization` **passed**: the
only identity value this file reads, `readTokenSubject()`'s `sub` claim, is
held only in an in-memory comparison variable and is never persisted,
transmitted, or exposed beyond that comparison.

`data-integrity` and `data-minimization` are **passed** because both rest on `watchSession`, whose behavior (vectors 012-015) is now tested.
