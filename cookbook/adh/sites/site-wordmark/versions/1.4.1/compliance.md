
| Check | Status | Category |
|---|---|---|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |

`separation-of-concerns` passes because `SiteWordmark.tsx` only composes registry lookup, the shared title split and theme tokens into markup, and ships on its own entry point so consumers do not pull in landing-page prose. `unit-test-coverage` fails because no test file exists for `SiteWordmark` anywhere under `packages/web` (the neighbouring `studioWordmark.test.tsx` covers `StudioWordmark`, a different component). These statuses otherwise rest on `SiteWordmark.tsx`: the brand and identity lines are plain text nodes with no ARIA suppression, read in document order (screen-reader-support); `text-apt-gold`/`text-apt-text`/`text-apt-text-dim` resolve to runtime theme roles whose rendered contrast is a property of the active theme, not measured or asserted by this component (contrast-ratio).

