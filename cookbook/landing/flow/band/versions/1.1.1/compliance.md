
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`semantic-markup` passes because Band always renders a real `<section>` element. `contrast-ratio` is partial because Band pairs a background and ink color per tone (the source shows the pairing), but does not compute or verify the actual rendered contrast, which depends on whatever values a host supplies for `--lp-ground`, `--lp-tone-soft`, `--lp-tone-paper`, `--lp-ink`, and `--lp-paper-ink`. Best-practices statuses rest on `Band` being pure presentation composing `Wrap` with no embedded logic (separation-of-concerns: passed), and on `flow.test.tsx` directly rendering `Band` and asserting its tone/seam class output (unit-test-coverage: passed).

