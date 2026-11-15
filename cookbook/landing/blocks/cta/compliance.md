
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

The status rests on the source rendering a plain `div` with a single static class (`lp-cta`) and no ARIA roles, states, or properties of its own — nothing for `Cta` to get wrong, and nothing that conflicts with the roles its children (buttons, links) supply. `separation-of-concerns` passes because `Cta.tsx` is pure presentation over its `children` prop with no business logic; `unit-test-coverage` is partial because `Cta.test.tsx` covers cta-001 to cta-005 and cta-007 and the computed-style half of cta-008, but the half of cta-008 where children wider than the container wrap onto a second row is skipped: jsdom does no layout.

