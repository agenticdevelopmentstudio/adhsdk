
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

Passed because the source (`Glow.tsx`) sets `aria-hidden` directly on the rendered `<div>`, correctly using ARIA to hide this purely decorative element from the accessibility tree. `separation-of-concerns` is `passed` because the component is pure presentation with no children and no logic beyond a class-name join; `unit-test-coverage` is `partial` because no test renders `Glow` directly — `deck.test.tsx` and `blocks-close.test.tsx` only assert its `.lp-glow`/`aria-hidden` output through the `Screen` and `Hero` parents that compose it.

