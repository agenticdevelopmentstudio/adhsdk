
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.performance.caching-strategy](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/3b773606-ab90-5e7d-8e96-093777dcf070) | passed | performance |
| [adc.check.performance.resource-efficiency](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d5fe7b8e-1051-5581-b2c5-1adae8fdd5fc) | passed | performance |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | reliability |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | security |
| [adc.check.security.token-lifecycle](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/61edfc73-f26a-5cfa-8c09-d1011eb8b7cd) | passed | security |

Separation of concerns is partial: one file holds the event builder, the context builder, the wire parser and the cache, though each is a distinct type or function with its own comment. Unit-test coverage is partial: `HookEnvelopeBuilderConformanceTests.swift` covers 31 of 35 vectors. builder-027, builder-028, builder-029 and builder-030 are skipped because `HookEnvCache` has no injectable resolver and keeps its maps private, so resolution counts and eviction cannot be observed (builder-030 also needs more than three real seconds). builder-031 is tested for no-crash only. The caching strategy and resource efficiency are passed: the cache bounds a process-table scan to once per three seconds per key and is size-checked. Graceful degradation is passed because every lookup failure leaves a built event with fields absent rather than an error. Input sanitization is partial because the wire parser is lenient but the unchecked `ppid` conversion is the open question on `ppid-range`. Token lifecycle is passed because the token is recovered per event, used only for the account lookup and never stored in the event.

