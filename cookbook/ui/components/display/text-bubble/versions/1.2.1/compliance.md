
| Check | Status | Category |
|---|---|---|
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | partial | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | passed | Internationalization |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

Statuses rest on the source: the off-screen full-text span plus `aria-hidden` on the visible copy and the absence of any fixed font-size override on glyph spans pass outright (semantic-markup, dynamic-type-support); `colorFrom`/`colorTo` defaulting to `currentColor` with no contrast check of its own, and no built-in `prefers-reduced-motion` detection beyond the `active` prop hosts may gate, are partial (contrast-ratio, reduced-motion); and `getComputedStyle(host).direction` driving reading order plus the `\p{Script=…}` cursive-script regex pass outright (rtl-layout-support, unicode-support). `separation-of-concerns` passes: the sweep, measurement, and DOM-splitting logic lives entirely in the `useTextBubble` hook, separate from the `TextBubble` presentational component, which only renders `text` and attaches the ref. `unit-test-coverage` is failed: no test file exercises `TextBubble` or `useTextBubble`.

