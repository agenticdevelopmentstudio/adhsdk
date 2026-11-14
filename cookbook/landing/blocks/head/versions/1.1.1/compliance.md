
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

The title renders as a native `h2` (semantic-markup), and `blocks.css` sizes the eyebrow and title with `rem`/`vw` units that scale with the root font size (dynamic-type-support). Neither the component nor `.lp-head h2` sets the heading's foreground color — it inherits from the surrounding page — so contrast cannot be confirmed from the source alone (contrast-ratio: partial). `separation-of-concerns` is `passed` because the component is pure presentation over `eyebrow`/`title`/`children` props with no business logic; `unit-test-coverage` is `passed` because `blocks-frame.test.tsx` renders `Head` directly and asserts its eyebrow/title rendering.

