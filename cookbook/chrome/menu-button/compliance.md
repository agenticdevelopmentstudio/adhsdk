
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | passed | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | failed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Statuses rest on `packages/web/packages/chrome/src/MenuButton.tsx` (the required `label` prop rendered as `aria-label` on a native `<button>`, with no custom ARIA roles needed) and `packages/web/packages/chrome/src/css/base.css` (`position: relative` plus the 44px `::after` hit area satisfy touch-target-size; the absence of any `prefers-reduced-motion` rule fails reduced-motion). `separation-of-concerns` passes: the component is a single-purpose presentational element (bars in, click-through button out) with no owned business logic or state beyond the `icon` prop it renders from. `unit-test-coverage` passes: `packages/web/packages/chrome/src/__tests__/MenuButton.test.tsx` covers every conformance vector.

Focus visibility has no requirement and no vector: `packages/web/packages/chrome/src/css/base.css` defines no `:focus-visible` style, so the icon-only button relies on the browser's default outline, which a consumer's reset may remove. This is a gap, not a pass.
