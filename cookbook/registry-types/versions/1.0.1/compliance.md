
This is a non-UI logic package with no network calls, no rendered surface, and no session/token handling, so the platform-design, touch-target, deep-linking, offline, retry, and authentication-related compliance categories do not apply. The checks below are the ones this package's own code exercises.

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | Security |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | passed | Reliability |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`input-sanitization` is partial: `validateFieldValue` gates every value before `coerceFieldValue` or `searchableText` act on it (**validate-before-coerce**), but address sub-fields and the `showIf` field lookup go unchecked (the open questions under **address-subfield-validation** and **show-if-field-lookup**). `fault-tolerance` passes because an unrecognized field type, an unrecognized `show_if` operator, a malformed `in` rule, and a pathologically deep comparison value are all handled with a defined return value rather than a thrown exception (**unrecognized-type-rejected**, **show-if-unknown-op-fails-open**, **show-if-malformed-in-fails-open**, **compare-depth-cap**). `no-hardcoded-strings` fails because every `validateFieldValue` error message is a hardcoded English literal with no localization hook — see Localization above. `show-if.ts`, `types.ts`, `validate.ts`, and `visibility.ts` are non-UI logic with no rendering to entangle (separation-of-concerns passed); the package's own `src/__tests__/show-if.test.ts`, `validate.test.ts`, and `visibility.test.ts` (566 lines across the three files, not the unrelated candidates the evidence search surfaced) directly and thoroughly exercise every one of these source files (unit-test-coverage passed).

