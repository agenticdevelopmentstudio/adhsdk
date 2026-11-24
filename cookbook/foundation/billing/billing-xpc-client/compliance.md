
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

separation-of-concerns passes: the client only translates the service interface to transport calls and wire coding; rules are the daemon's and the transport is injected. unit-test-coverage passes: `BillingXPCClientTests` covers every vector (001 to 013), including the failing list read (002), the zero count (010) and the exact refusal sentence (004).

