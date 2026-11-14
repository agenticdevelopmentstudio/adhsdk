
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

`semantic-markup` passes because the component always renders a real `<footer>` element, which carries the correct implicit `contentinfo` landmark role when placed as a direct page-level child (see **Accessibility**). `contrast-ratio` is partial because `flow.css` pairs `--lp-ground`/`--lp-ink-dim` for the footer body and `--lp-ink`/`--lp-ground` for its links (see **Appearance**), but the actual rendered contrast depends on whichever values a host supplies for those custom properties, which the source neither computes nor verifies. `separation-of-concerns` passes because `SiteFooter.tsx` is pure presentation, wrapping its children with no business logic. `unit-test-coverage` is partial because `flow.test.tsx`'s `SiteFooter` block asserts only on the `.lp-site-foot a` CSS rule, not on the component's own render output — no test calls `render(<SiteFooter>)` directly.

