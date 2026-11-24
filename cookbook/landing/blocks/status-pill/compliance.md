
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | partial | Accessibility |
| [adc.check.internationalization.text-expansion-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8007859b-a974-5b8a-88f7-162624b0c056) | failed | Internationalization |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

- contrast-ratio partial: with the fallback colors, the default text `#9a9a9a` on the `--lp-ground` fallback `#101010` is 6.76:1 (6.06:1 on `--lp-raise` `#1c1c1c`), and the accented text `#d8d8d8` is 13.35:1 on `#101010`; both pass WCAG AA for normal text. The status stays partial because the real background and the `--lp-*` values come from the host theme, and the 0.62rem uppercase size is small.
- dynamic-type-support partial: `blocks.css` uses a fixed `rem` size; native ports are told to use a scalable text style (see Platform Notes), but none is verified.
- semantic-markup partial: the root is a `<p>`, which has paragraph semantics and nesting limits (see #edge-cases/nesting-inside-inline-only-content).
- text-expansion-tolerance failed: `white-space: nowrap` with no truncation means expanded translations overflow rather than adapt.
- string-externalization passed: all displayed text is caller-supplied.
- separation-of-concerns passed: the component is a single conditional class over caller-supplied children with no business logic.
- unit-test-coverage passed: `packages/web/packages/landing/src/__tests__/status-pill.test.tsx` has one passing test for each of status-pill-001 to status-pill-007. The nowrap vector injects `blocks.css` into the jsdom document and reads the computed `white-space`.
