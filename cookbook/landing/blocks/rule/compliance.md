
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

- semantic-markup passed: the source renders `<dl>`/`<dt>`/`<dd>` directly (`packages/web/packages/landing/src/blocks/Rule.tsx`).
- dynamic-type-support partial: the web CSS (`packages/web/packages/landing/src/css/blocks.css`) sizes `dt`/`dd` in `rem` units, which scale with the root font size. The Platform Notes now give native text-scaling guidance, but no native port exists to verify it.
- no-hardcoded-strings passed: `term` and `detail` are supplied entirely by the caller, with no string literals in `Rule.tsx`.
- separation-of-concerns passed: `Rule.tsx` is a trivial pure-presentation mapping of `steps` to `dt`/`dd` pairs with no logic of its own.
- unit-test-coverage partial: `packages/web/packages/landing/src/__tests__/blocks-argument.test.tsx` covers rule-001 to rule-009 with passing tests. rule-010 is skipped because it describes a missing `steps` value, which the typed web source cannot receive.
