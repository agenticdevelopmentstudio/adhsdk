
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | failed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

The native `<button>` element with rest-prop passthrough satisfies screen-reader-support, keyboard-navigable and semantic-markup. `touch-target-size` is `failed`: the shipped stylesheet gives a height of about 35px, under the 44px target of WCAG 2.5.5 (it does meet the 24px minimum of WCAG 2.5.8). `contrast-ratio` is `partial`: with the default tokens, primary text on its accent background is about 8:1, but destructive text on its dim red fill is about 4:1, under 4.5:1. `separation-of-concerns` passed: `SettingsButton.tsx` is pure presentation over props. `unit-test-coverage` is `partial`: `SettingsButton.test.tsx` covers settings-button-001 to 011, 013 and 014; settings-button-012 (the closed variant set) is skipped because it is a compile-time check and vitest does not type-check.
