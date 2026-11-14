
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`keyboard-navigable` passes because the source renders a native HTML `<input>`, which is keyboard-operable by default with no custom key handling to verify. `screen-reader-support`, `contrast-ratio`, and `touch-target-size` are `partial`: the source itself provides no accessible name (an external `<label>` is required), its M3 color tokens are resolved outside this file so contrast can't be confirmed here, and its fixed 36px height meets the WCAG 2.5.8 minimum but not Android's or iOS's native minimums. `separation-of-concerns` passes because the component is a thin themed wrapper over the native `<input>` with no business logic beyond the `autoComplete`-precedence guard; `unit-test-coverage` passes on `autofill.test.tsx`'s direct exercise of that autofill opt-out/token behavior against `Input`.

