
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | passed | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`semantic-markup` and `no-hardcoded-strings` rest on `Explanation.tsx` rendering a `<p>` element whose only content is the caller-supplied `children` prop, with no literal user-facing strings in the source. `contrast-ratio` is `passed` for the default theme: the `--aws-text-muted` fallback `#8a8a9a` measures about 5.75:1 against the `.aws-panel` background fallback `#0c0c0f`, above the 4.5:1 WCAG 2.1 AA minimum for normal text; a consumer theme that overrides either token must be re-measured. `separation-of-concerns` is `passed` because the component is pure presentation over `children` with no logic beyond a class-name join; `unit-test-coverage` is `passed` because `Explanation.test.tsx` covers all fourteen conformance vectors (explanation-001 to explanation-014).

