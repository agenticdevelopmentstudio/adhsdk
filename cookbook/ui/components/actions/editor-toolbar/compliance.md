
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | partial | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | failed | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

`semantic-markup` is `partial` because the source (`editor-toolbar.tsx`) sets `role="toolbar"` and `aria-label` but does not guard an explicitly empty `ariaLabel`, and the `toolbar` role doesn't fully match the keyboard behavior it implies; `keyboard-navigable` is `failed` because the source has no focus or keyboard handling at all; `no-hardcoded-strings` is `failed` because the default `"Editor toolbar"` string is a literal in the source rather than a localization lookup. `separation-of-concerns` is `passed` because the source is pure layout over props with no business logic; `unit-test-coverage` is `failed` because `markdownSpellcheck.test.tsx` exercises a different control and no test renders `EditorToolbar` itself.

