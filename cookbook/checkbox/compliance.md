
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`semantic-markup` passes on the Wrapper's native `<input type="checkbox">` with `role`/`htmlFor` semantics and the Primitive's `role="checkbox"` span supplied by Base UI. `screen-reader-support` relies on the Wrapper linking its hint to the input through `aria-describedby` (see **hint-description-association**). `keyboard-navigable` is partial because the Wrapper's native input is keyboard-operable but the Primitive's `<span role="checkbox">` gets its keyboard behavior from Base UI and no test confirms it. The `contrast-ratio` and `touch-target-size` partial statuses reflect that the `apt-*` token contrast values and the effective click-target size (label padding/line-height) are defined in an external stylesheet not present in either source file. The Wrapper's own logic — id generation, conditional label/hint rendering, and appearance-driven role selection — is kept out of the Primitive, which delegates all checked/disabled behavior to Base UI and limits its own file to `apt-*` styling (separation-of-concerns). `checkbox.test.tsx` (controls `user-settings/__tests__` for the Wrapper, ui `__tests__` for the Primitive) covers all 23 vectors with passing tests, so `unit-test-coverage` passes.
