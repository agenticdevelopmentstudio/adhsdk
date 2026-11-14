
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.access-patterns.api-design-conventions](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b6745c95-4ef2-5ab4-8791-00ffc1d7b82d) | passed | Access Patterns |

`separation-of-concerns` passes because the table only orders and dispatches handlers; the HTTP transport, the handlers' business logic and what to do with an unclaimed request belong to the daemon and its routes. `unit-test-coverage` is partial: `RouteTableTests` covers first-claim-wins, an unclaimed request, merge order and fall-through, and the exact handler's method, path, extra-segment and empty-path cases, but vectors 009 to 013 (method case-sensitivity, empty-segment matching, non-mutating merge, later handlers skipped, sequential await) are derived and have no test. `api-design-conventions` passes because dispatch is one deterministic rule, ordered first-claim-wins, over a transport-free request.

