
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

All three statuses rest on `button-pressable.tsx` forwarding every prop other
than the five intercepted pointer handlers unchanged (so any `aria-*`/label
props a caller supplies reach the rendered element untouched), never
registering its own keyboard handling (Space/Enter activation stays with the
underlying Base UI `Button` primitive), and reflecting press state via the
plain `data-pressed` data attribute rather than any ARIA role or state.
Best-practices statuses reflect that the held/pressed pointer state machine
is inlined in this component's own render rather than separated apart from
it — splitting the file from `button.tsx` keeps interactivity apart from the
plain module, but not apart from this file's own rendering
(separation-of-concerns: partial) — and that no test in the suite exercises
`PressableButton` (unit-test-coverage: failed).

