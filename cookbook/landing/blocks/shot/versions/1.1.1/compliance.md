
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | passed | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

Statuses rest on `Shot.tsx` and its CSS: text sizes are set in `rem` (`.lp-shot__name` 0.7rem, `.lp-shot__placeholder` 0.78rem), so `dynamic-type-support` passes; foreground/background colors are CSS custom properties with fallback values whose final computed contrast depends on the host theme, so `contrast-ratio` is partial; and the component applies no explicit ARIA roles or `aria-hidden`, relying on the dots being empty (no accessible name) and the title/caption/pendingLabel being ordinary text nodes, so `semantic-markup` is partial. `separation-of-concerns` passes: `Shot` is a pure presentational function with no business logic, data fetching, or state, rendering exactly the `media`/`caption`/`pendingLabel` props it is given. `unit-test-coverage` is partial: `blocks-frame.test.tsx` covers frame-chrome/title-in-bar, media-verbatim (the `<video>` case), and pending-label-above-caption, but not the `<img>` media variant or the falsy/empty caption and pendingLabel edge cases.

