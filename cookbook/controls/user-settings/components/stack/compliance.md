
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

This rests on the source rendering a plain `<div>` with no `role` or other ARIA attribute, and never forwarding `role` or other rest props onto it (see **no-rest-prop-forwarding**); `VStack`/`HStack` are pure presentation over props with only a trivial `gapValue` helper (separation-of-concerns passed), and no test file exercises `Stack.tsx` — the candidate tests matched by name are unrelated Swift and avatar-engine files (unit-test-coverage failed).

