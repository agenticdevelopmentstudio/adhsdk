
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | accessibility |

The module separates the stack side from the pane side behind two contexts, which passes separation of concerns. `detailTitle.test.tsx` covers registration, last-registrant-wins, the heading role, the fallback and opt-out, unmount withdrawal and the held label through a real stack, and `stack-frontier.test.ts` covers `deepestSelectedLevel`; `detailTitleBlock.test.tsx` carries a test for every vector (detail-title-001 to 020), including the registrar's idempotency, the depth-keyed hold and server rendering, so unit-test coverage passes. The strip cell is a heading with a level, which passes semantic markup. The muted token's contrast is not measured in source, so contrast is partial.

