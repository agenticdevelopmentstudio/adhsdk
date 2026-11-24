
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

`semantic-markup` passes because the component always renders a real `<footer>` element, which carries the correct implicit `contentinfo` landmark role when mounted as a sibling of the `Flow` container, outside `<main class="lp-flow">` (see **mount-outside-flow** and **Accessibility**). `contrast-ratio` is partial. With the fallback values in `packages/web/packages/landing/src/css/flow.css` it passes: the body text `#a0a0a0` on `#101010` has a contrast ratio of about 7.3:1 and the link text `#ededed` on `#101010` about 16.3:1, both above the 4.5:1 AA minimum. It stays partial because a host can override `--lp-ground`, `--lp-ink-dim` and `--lp-ink`, and the source neither computes nor verifies the contrast of those values. `separation-of-concerns` passes because `SiteFooter.tsx` is pure presentation, wrapping its children with no business logic. `unit-test-coverage` is partial: `flow-conformance.test.tsx` renders the component for site-footer-001 to site-footer-007; site-footer-008 to site-footer-014 are skipped because they assert computed styles, hover or the accessibility tree and need a real browser.

