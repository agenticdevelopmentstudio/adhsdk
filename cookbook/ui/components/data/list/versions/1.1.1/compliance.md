
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | partial | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

Status rests on `list.tsx`: it renders plain `<ul>`/`<li>` elements with correct implicit roles, but it forwards an overridable `role` prop (**prop-forwarding**) and does not add `role="list"` to guard against Safari/VoiceOver dropping list semantics on a flexed `<ul>` (see Accessibility). `separation-of-concerns` passes because `List`/`ListItem` are pure presentation over their props with no logic beyond prop forwarding; `unit-test-coverage` fails because no test file imports `components/list`.

