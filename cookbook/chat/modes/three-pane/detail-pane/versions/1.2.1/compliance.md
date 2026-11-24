
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | failed | Accessibility |
| [adc.check.performance.image-optimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/433c7317-4c29-5100-8524-ef3e34ac5588) | failed | Performance |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

`semantic-markup` fails because the pane is built entirely from `div` elements: the "Details" header and the topic title are `div`s rather than heading elements, and the root carries no landmark role (see **header-semantics**). `image-optimization` fails because each `<img>` is rendered with only `src` and `alt` — no `loading`, `decoding`, `width`, or `height` attributes — so images load eagerly and reserve no layout space. `string-externalization` fails because "Details" and "Links" are literal English strings with no localization key, catalog, or translation hook (see Localization, **literal-ui-strings**). `separation-of-concerns` passes because `DetailPane.tsx` only renders the `TopicData` it is handed — no data fetching, backend calls, or business rules live in the component. `unit-test-coverage` fails because no test file in the `chat` package exercises `DetailPane`.

