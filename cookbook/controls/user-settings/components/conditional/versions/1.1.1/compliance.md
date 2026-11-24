
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

The `passed` status rests on the component's fragment-based render (`<>{when ? children : fallback}</>`), which adds no wrapper node and therefore preserves whatever ARIA roles and semantic structure the rendered branch already has. separation-of-concerns passes because `Conditional.tsx` renders via a single ternary inside a fragment with no state or business logic of its own, and unit-test-coverage passes because `components.test.tsx`'s `Conditional` suite exercises the true/false branches, the default-fallback case, and array/mixed children with meaningful assertions.

