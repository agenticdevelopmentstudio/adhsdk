
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | Reliability |
| [adc.check.best-practices.test-pyramid](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/203de556-83a8-5211-acaf-155c49da0eb3) | passed | Best Practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |

Notes: separation-of-concerns passes because the source itself distinguishes
"the pure core" (`facets(text:capabilities:)`) from the `AIModelCatalog`-aware
convenience wrapper (`facets(for:extraText:)`), and keeps filtering
(`matches`) as a third, independent function. graceful-degradation passes
because an evidence-free model always passes `matches(...)` rather than being
hidden (see `filter-unknown-model-passes`). test-pyramid passes because
`ModelUseFacetTests.swift` exercises the pure derivation and filter logic
directly, with no UI, network, or file-system dependency in the test suite.
no-hardcoded-strings fails because `title` and `detail` return English-only
`String` literals with no localization mechanism (see Localization).

`unit-test-coverage` passes because `ModelUseFacetTests.swift` covers facet derivation from description prose, word-prefix anchoring, phrase evidence, capabilities implying facets, the any-of filter semantics, an empty selection filtering nothing, an evidence-free model always passing, and every facet having a title and tooltip.

