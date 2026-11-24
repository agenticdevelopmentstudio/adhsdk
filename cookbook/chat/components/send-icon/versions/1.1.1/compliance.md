
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | failed | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

`screen-reader-support` is partial because SendIcon itself supplies no label and relies on a wrapping control to provide one — the reference usage in `ChatInput.tsx` does this correctly with `aria-label="Send"` on its `<button>`. `semantic-markup` fails because the `<svg>` in `SendIcon.tsx` sets no `aria-hidden` or `focusable` attribute, so nothing tells assistive technology to skip this purely decorative graphic. `separation-of-concerns` passes because `SendIcon.tsx` is a pure, prop-less presentational SVG with no logic at all, and `unit-test-coverage` fails because no test exercises it.

