
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | partial | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

Statuses rest on `Group.tsx` rendering semantic `<section>`/`<h3>`/`<p>` elements with no ARIA attributes and no accessible name wired to the section (see **Accessibility**), and on the component deferring all typography, color, and spacing to CSS classes (`aws-group*`) that it does not itself define, so dynamic type and contrast cannot be confirmed from the source. `separation-of-concerns` is `passed` because the component is pure presentation over `title`/`hint`/`children` props with no business logic; `unit-test-coverage` is `failed` because no test exercises `user-settings/components/Group.tsx` — the candidate tests found by name (`AnimTests.swift`, `ConfigTests.swift`, etc.) test unrelated avatar-engine code, not this component.

