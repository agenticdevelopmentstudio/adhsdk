
| Check | Status | Category |
|---|---|---|
| [adc.check.platform-compliance.platform-theming](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d2b685fd-b481-5d38-bd70-403bd202b5c6) | passed | Platform Compliance |
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | Platform Compliance |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.locale-aware-formatting](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c87ff1f1-9d77-5167-b0c4-f13f2aae5acb) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Statuses rest on the source: it styles every element through `apt-*` tokens with no raw hex and
composes only the shared `Button`/`Popover` primitives (no bespoke controls); it sets
`aria-pressed`, `aria-hidden`, and a subject-naming `aria-label` correctly on every control; and
it builds its accessible-name and count text as hardcoded English template literals with no
`Intl.NumberFormat` call, which is what fails the three internationalization checks. The component
is explicitly presentational — the caller fetches tallies and performs the toggle, never the bar
itself (separation-of-concerns passed); `reactionBar.test.tsx` directly exercises chip labeling,
pressed state, toggle/take-back, the palette, busy inertness, and the disabled/empty-reactions
cases (unit-test-coverage passed).

