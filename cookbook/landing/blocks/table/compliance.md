
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | Internationalization |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | failed | Accessibility |

- semantic-markup passed: the source uses native `<table>`/`<th scope="col">`/`<caption>` markup.
- no-hardcoded-strings and string-externalization passed: every string comes from the caller via props.
- dynamic-type-support and contrast-ratio partial: font size and color come from the `lp-table`/`lp-sr-only` CSS classes in `blocks.css`, so they cannot be confirmed from the component source alone.
- separation-of-concerns partial: the row-width validation (`rows.find`/`throw`) runs inline in the render function rather than as a separate helper.
- keyboard-navigable failed: the `lp-table-scroll` wrapper scrolls horizontally (`overflow-x: auto`) but the source sets no `tabindex`, `role` or accessible name on it, so a keyboard user cannot scroll a wide table (WCAG 2.1.1, axe `scrollable-region-focusable`).
- unit-test-coverage passed: `packages/web/packages/landing/src/__tests__/table.test.tsx` has one passing test for each of table-001 to table-015, including the exact error text, which bad row is reported, and the empty and ReactNode cases.
