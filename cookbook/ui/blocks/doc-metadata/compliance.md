
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | failed | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Semantic-markup passes because the source renders proper `<dl>`/`<dt>`/`<dd>` elements; contrast-ratio is partial because the label and value colors are unresolved theme CSS variables (`--color-text-dim`, `--color-text-secondary`) whose computed ratio the source cannot tell you; dynamic-type-support fails because the source hardcodes a fixed 11px font size (`text-[11px]`) that does not scale with system text-size settings. `separation-of-concerns` passes because `DocMetadata` renders the caller-supplied `fields` with no formatting logic of its own; `unit-test-coverage` passes because `docMetadata.test.tsx` imports `DocMetadata` directly and exercises its behavior with meaningful assertions.

