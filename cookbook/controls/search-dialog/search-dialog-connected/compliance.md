
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Keyboard handling, focus management, and ARIA structure live entirely in SearchDialog and useSearchState; this wrapper forwards `open`, `onClose`, and the rest of SearchDialogProps unmodified (see **forwarded-props**), so the source shows it does not break that behavior but, as a pass-through layer, cannot itself demonstrate full conformance. `separation-of-concerns` passes because this component only wires data hooks (`useContent`, `useSiteConfig`, `useCurrentRoute`, `useSearchState`) and delegates all rendering to `SearchDialog`, and `unit-test-coverage` passes because `SearchDialogConnected.test.tsx` renders it with real providers and asserts on the resulting navigate/close calls.

