
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

The first two rest on the `.lp-wrap` rule in `base.css`: the cap and gutter are expressed in `rem`, so they scale with root font-size / type-size settings, and Wrap renders a plain `div` with no ARIA roles or attributes of its own to misuse. `separation-of-concerns` passes because `Wrap.tsx` itself holds no width/gutter logic at all — it only joins class names — and that logic lives entirely in the `.lp-wrap` CSS rule. `unit-test-coverage` is partial: `deck.test.tsx`'s `Wrap` block only confirms the `lp-wrap` class is applied; the `min()` cap-vs-gutter behavior this revision corrects is expressed in CSS and has no unit test (jsdom does not compute layout), so it can only be verified by reading the stylesheet.

