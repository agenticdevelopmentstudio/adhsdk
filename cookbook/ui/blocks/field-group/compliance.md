
| Check | Status | Category |
|---|---|---|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | passed | Accessibility |
| [adc.check.platform-compliance.platform-theming](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d2b685fd-b481-5d38-bd70-403bd202b5c6) | passed | Platform Compliance |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

`semantic-markup` and `contrast-ratio` are partial because the source renders a
correct `<h3>` heading and resolves every color through `apt-*` tokens, but the
root `<section>` has no accessible name to be exposed as a landmark region, and
the source does not state the tokens' resolved contrast values.
`dynamic-type-support` is passed because the title uses `fieldCaptionClass`'s
`text-[0.7rem]`, a `rem`-based size that scales with the user's base font
setting. `platform-theming` is passed because every color in the source
(`apt-border`, `apt-surface-2`) resolves through a theme token, with no raw hex
and no `!important`. `separation-of-concerns` is passed because the component
is pure layout over `title`/`trailing`/`children` props with no business logic;
`unit-test-coverage` is failed because no test exercises `field-group.tsx`.

