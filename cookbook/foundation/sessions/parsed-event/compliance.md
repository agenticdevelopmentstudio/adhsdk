
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

separation-of-concerns passes: the type only stores one event's fields, while parsing is `ParseResult`, encoding is the envelope extension and persistence is the spool and ingest store. unit-test-coverage is partial: `Tests/AgenticDeveloperHubSDKCoreTests/Sessions/ParsedEventConformanceTests.swift` covers parsed-event-001 to 009; parsed-event-010 is skipped because it is a static check (every stored property is `let`), not a runtime test.

