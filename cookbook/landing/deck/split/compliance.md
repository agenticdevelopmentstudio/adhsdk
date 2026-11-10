
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | partial | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

Statuses rest on `Split.tsx` rendering a bare `<div>` with no ARIA role or attributes (semantic-markup), and on `css/base.css` defining the two-column grid with no explicit `direction` override, which gives native RTL mirroring but is not yet exercised by an automated test (rtl-layout-support). `separation-of-concerns` passes because `Split.tsx` is pure presentation, with all layout values living in CSS rather than the component. `unit-test-coverage` fails because no test in the repository renders `Split` — the landing package's `deck.test.tsx` covers `Screen` and `Deck` but not `Split`.

