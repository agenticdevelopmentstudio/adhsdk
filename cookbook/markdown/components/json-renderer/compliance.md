
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.performance.lazy-loading](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/93049d53-e8e2-5ea3-8a3a-9eb07e60d0e2) | partial | performance |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | internationalization |

Parsing, fencing and class-list logic live in small pure helpers (`prettyJson`, `fenceCode`, `proseClassName`) and Markdown rendering stays in `MarkdownRenderer`, so the component only chooses between two paths: that meets separation-of-concerns. Unit-test coverage passes: the helpers have tests and `jsonRenderer.test.tsx` covers all 14 vectors against the component. Performance is partial: the size limit protects the page from a slow highlight, but the pretty-print itself runs synchronously on the render thread for any size. Semantic markup passes because output is a `pre` and `code`: `pre.shiki` for valid JSON and for the oversized plain path, and a bare `pre` for invalid text, which is fenced with no language and so is not highlighted. `jsonRenderer.test.tsx` asserts `pre.shiki` wherever the source produces it. Keyboard navigation is partial: below the limit the shiki `pre` is focusable, but the open question on `keyboard-scroll` remains for the oversized plain `pre`, which is not. No-hardcoded-strings fails on the open question on `note-string`.

