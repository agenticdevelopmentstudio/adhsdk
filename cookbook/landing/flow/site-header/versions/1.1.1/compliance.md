
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Statuses rest on `SiteHeader.tsx` rendering a semantic `<header>` element, a `<nav>` element with an `aria-label` (defaulting to `'Site'`), and real `<a>` anchors for every navigation link — native landmarks and native anchors are screen-reader-discoverable and keyboard-focusable without additional ARIA. `separation-of-concerns` passes because `SiteHeader` composes the existing `NavChrome` for the drawer/burger behavior and only adds its own bar/wordmark/action layout, rather than reimplementing navigation chrome. `unit-test-coverage` passes because `site-header.test.tsx` imports `SiteHeader` directly and asserts on brand/nav/action rendering, the `bar='nav'`/`'drawer'` variants, and the breakpoint-driven centering and scroll behavior.

