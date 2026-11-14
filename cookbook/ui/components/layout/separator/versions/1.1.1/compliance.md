
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

`separator.tsx` sets `role="separator"` and keeps `aria-orientation` synced to the `orientation` prop on every render, which is correct ARIA usage for a non-interactive separator. The other Accessibility checks (screen-reader-support, keyboard-navigable, touch-target-size, focus-management) do not apply because the component has no interactive functionality, and dynamic-type-support/contrast-ratio do not apply because it renders no text. `separation-of-concerns` passes because `separator.tsx` is pure presentation with no business logic, and `unit-test-coverage` fails because no test exercises it — its only consumer, `user-card.tsx`, itself has no test.

