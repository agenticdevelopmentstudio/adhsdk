
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Both statuses rest on the source's deliberate `tabIndex={-1}` focus handling and its `<div>` (not `<main>`) root, documented directly in `Deck.tsx`'s comment block and exercised by its test suite. `separation-of-concerns` passes because `Deck.tsx` is pure presentation over its `children` and `className` props, with no business logic; `unit-test-coverage` passes because `deck.test.tsx` renders `<Deck>` directly and asserts on its output.

