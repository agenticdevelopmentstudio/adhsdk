
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.access-patterns.timeout-configuration](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dc15eb62-a72c-5b09-b9e7-c1bed983f499) | passed | Access Patterns |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | partial | Access Patterns |
| [adc.check.access-patterns.retry-with-backoff](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bcb17bfe-d2d6-53f3-b2af-06b7eea3da61) | failed | Access Patterns |
| [adc.check.security.secure-transport](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0a75f61f-9508-506e-b92e-0f5b29a91c95) | partial | Security |

`separation-of-concerns` passes because the client only moves requests and replies; the wire spelling, identifiers and DTOs live in their own types. `unit-test-coverage` passes because every vector has a test in `StenographerHTTPClientTests` (`Tests/AgenticDeveloperHubSDKCoreTests/Stenographer/StenographerHTTPClientTests.swift`): the failure mapping, query building, the 404, the summarize and action failures, both preference encoders, the reconnect trigger and its first-poll and failed-poll cases, `timeout(method:path:)`, URL construction, the content type and the default base URL. `timeout-configuration` passes because every request carries one of three explicit timeouts. `error-response-handling` is partial because the daemon's `error` text is surfaced only for summarize and finding actions; every other failure collapses to `nil` or `false` by design. `retry-with-backoff` is marked failed because the client never retries; that is deliberate (see the Design Decision "The client does not retry or back off"), since the caller decides and the daemon is on loopback, so the check is a known and accepted failure rather than a defect. `secure-transport` is partial because traffic is plain HTTP, which is acceptable only on the loopback address, and the base URL can be overridden to any address through `STENOGRAPHER_URL`.

