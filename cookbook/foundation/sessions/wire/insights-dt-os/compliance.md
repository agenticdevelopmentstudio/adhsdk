
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.access-patterns.api-design-conventions](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b6745c95-4ef2-5ab4-8791-00ffc1d7b82d) | passed | access-patterns |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | reliability |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | internationalization |

Separation of concerns passes: both files hold only data shapes, with computation in `DaemonDatabase`'s insights, rollup and graph queries and transport in `UsageRoutes`. Unit-test coverage is partial: `InsightsQueriesTests` asserts the field values the producers put into the insights types, but no test encodes or decodes any of the types themselves, so the snake_case wire names, the omitted `most_used_tool` and `status` keys and the verbatim `by_type` keys are untested, and no test exercises `graphSnapshot` at all. API design conventions pass: one key-naming rule applies to every field, the cache-miss report documents its sentinels, its floor-not-estimate cost and its truncation rule, and graph node ids are namespaced so link endpoints are unambiguous. Data integrity is partial: the doc comments state each count's meaning precisely, but the `DailyMetricDTO` comment that `valueSum` is always 0 is contradicted by the `project` metric, and graph link-to-node integrity rests on the producer alone, with nothing in the types to enforce it. No user-facing strings exist; every literal is an identifier.

