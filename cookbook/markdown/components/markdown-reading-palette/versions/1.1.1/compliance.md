
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | passed | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

This rests on the four built-in themes' `--mdv-text`/`--mdv-bg` pairs in `themes/palettes.ts`, each of which computes to at least a 13.5:1 WCAG contrast ratio; contrast for any theme added later is the themes registry's responsibility, not this wrapper's runtime behavior. `separation-of-concerns` passes because the component is a pure presentation wrapper that delegates theme lookup to `getThemeById` from `../themes/registry`, with no business logic of its own; `unit-test-coverage` fails because no test file references `MarkdownReadingPalette`.

