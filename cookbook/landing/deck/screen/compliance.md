
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | partial | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Partial because Screen correctly switches between `<section>` and `<div>` based on the `as` prop (`Screen.tsx`), but exposes no `aria-label`/`aria-labelledby` prop and forwards no other attributes to its root, so a host using `as: 'section'` as a landmark cannot give that element an accessible name through Screen's own API. `separation-of-concerns` passes because `Screen.tsx` is pure presentation over props with no business logic of its own, and `unit-test-coverage` passes because `deck.test.tsx` renders it directly and asserts on its id, class, tag, and glow-ordering behavior.

