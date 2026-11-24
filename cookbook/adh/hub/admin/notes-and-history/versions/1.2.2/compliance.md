
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.platform-compliance.platform-theming](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d2b685fd-b481-5d38-bd70-403bd202b5c6) | passed | Platform Compliance |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | partial | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.locale-aware-formatting](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c87ff1f1-9d77-5167-b0c4-f13f2aae5acb) | partial | Internationalization |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

`platform-theming`/`separation-of-concerns` pass on every color in source
using the `apt-*` token vocabulary with no raw hex value or `!important`,
and on the component containing no data-fetching, caching, or
state-management code (see Design Decisions). The three accessibility
checks are `partial`: source uses relative-unit Tailwind text utilities and
semantic `<section>`/`<h4>` markup with no incorrect ARIA, but neither
Dynamic Type behavior nor token contrast ratios are verifiable from source
alone, and the missing `aria-live` wiring for the loading-to-populated
transition (see Accessibility: Announce state changes) is a real gap.
`string-externalization`/`no-hardcoded-strings` fail because all five
strings are English JSX literals with no translation call;
`locale-aware-formatting` is `partial` because `modifiedDate`/`timestamp`
arrive pre-formatted from `invitations-types.ts` (see Types) and the
component itself performs no formatting of its own.

`unit-test-coverage` fails: no test file for `notes-and-history.tsx` exists under the `adh-ui` test targets (`packages/web/packages/adh-ui/src/__tests__/` holds tests for other blocks only).

