
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Semantic structure and the landmark label come directly from the rendered `<nav aria-label="Breadcrumb">`, `<ol>`, and `<li>` markup. Keyboard operability is `partial`: the default `LinkComponent` renders a plain `<a href>`, which is natively keyboard-operable, but the component hands rendering to whichever `LinkComponent` the host injects and cannot guarantee that a custom one preserves the same behavior. `separation-of-concerns` passes because `DocBreadcrumbs` renders the caller-supplied `crumbs` array with no derivation logic of its own; `unit-test-coverage` passes because `docBreadcrumbs.test.tsx` imports `DocBreadcrumbs` directly and exercises its behavior with meaningful assertions.

