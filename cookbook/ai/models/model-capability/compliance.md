
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | passed | Reliability |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |

Notes: no-hardcoded-strings fails because `title` and `detail` return
English-only literals with no localization mechanism (see Localization).
idempotent-operations passes because every function on `ModelCapability`
is a pure, stateless function of its arguments (see `pure-and-stateless`
and the Concurrent access edge case). separation-of-concerns passes
because the source's own doc comment draws an explicit boundary between
this type's "does it have this" axis and `ModelUseFacet`'s "what's it
good for" axis, and derives `.conversation` by calling into
`ModelUseFacet` rather than duplicating its heuristic.

`unit-test-coverage` passes because `ModelCapabilityTests.swift` exercises the type directly: a reported capability being recognised, a curated tools flag counting, chat being read out of prose, and reasoning and vision never being inferred from prose, with `ProviderPickerTests.swift` covering its use in the picker.

