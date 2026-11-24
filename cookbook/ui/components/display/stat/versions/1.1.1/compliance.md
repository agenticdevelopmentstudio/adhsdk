
| Check | Status | Category |
|---|---|---|
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.platform-compliance.platform-theming](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d2b685fd-b481-5d38-bd70-403bd202b5c6) | passed | Platform Compliance |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`contrast-ratio` is partial because `stat.tsx` colors the value and label only
through `apt-*` tokens — no raw hex, no `!important` — without itself asserting a
measured ratio. `semantic-markup` passes because the component renders plain,
non-interactive `<span>`/`<div>` elements with no ARIA misuse. `platform-theming`
passes because every color comes from the shared `apt-*` theme tokens, which the
Appearance section states resolve consistently in light and dark. `StatRow`/`Stat`
are pure presentation over props with no business logic (separation-of-concerns
passed), and `stat.test.tsx` directly renders both and asserts on tone-class output
(unit-test-coverage passed).

