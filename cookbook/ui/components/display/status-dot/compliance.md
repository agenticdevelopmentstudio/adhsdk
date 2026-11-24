
| Check | Status | Category |
|---|---|---|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Statuses rest on the source's conditional `role="img"` / `aria-label` /
`aria-hidden="true"` rendering (`semantic-markup`), and on the fact that the
component never embeds a literal user-facing string — `label` is always a
value the consumer passes in (`no-hardcoded-strings`). `separation-of-concerns`
passes: `StatusDot` is a memoized, pure presentational component, and its
tone-to-class mapping is delegated to the shared `lib/tone` table rather than
computed inline. `unit-test-coverage` is passed: the `StatusDot` block in `stat.test.tsx` (the display
primitives test file; no `status-dot` test file exists) has one test per vector, T1 through T16,
including the `color-mix` glow, the small-size floor, the `neutral` tone override, verbatim labels
and memoization.
