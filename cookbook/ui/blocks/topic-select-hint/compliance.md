
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

Statuses rest on `topic-select-hint.tsx`: headline/description sizes use relative Tailwind units but are not verified against OS-level type scaling (dynamic-type-support); the `apt-*` tokens are referenced by name only with no resolved color values in source, so contrast cannot be confirmed (contrast-ratio); the headline renders as a plain `<div>` rather than a semantic heading or paragraph element (semantic-markup); and the computed headline's English words are literal string fragments in source, not externalized resources (no-hardcoded-strings); `TopicSelectHint` is presentation assembled over the `Card` primitive, with only simple string-building (`article`, the headline fallback) and no business logic or data access (separation-of-concerns passed), and no test file in the web workspace exercises this source (unit-test-coverage failed).

