
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

The source renders a plain, role-less `div` with no ARIA misuse (semantic-markup); it performs no check on whether the region it crops still leaves focusable content reachable, so that depends entirely on the caller keeping the bled area decorative-only (keyboard-navigable, see **Accessibility**). Best-practices statuses rest on `Bleed` being pure presentation over its `side`/`children`/`className` props with no embedded logic (separation-of-concerns: passed), and on `flow.test.tsx` directly rendering `Bleed` and asserting its side-modifier class output (unit-test-coverage: passed).

