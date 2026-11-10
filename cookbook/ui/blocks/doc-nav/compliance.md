
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | failed | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

These statuses rest on: theme-token text colors used throughout for contrast; every interactive control (section toggle, links, drawer close button) being reachable and operable via tab and enter, with the scrim providing only a redundant pointer-only dismiss path alongside the keyboard-operable close button; semantic `<nav>`/`<ul>`/`<li>` markup with the host's `LinkComponent` (defaulting to `<a href>`) and `aria-expanded`/`aria-label` on the section toggle plus `aria-current="page"` on selected links; section-toggle buttons padded to 44×44px while link rows measure roughly 24-28px tall, short of that minimum (see Accessibility); and no `prefers-reduced-motion` handling anywhere in the source for the chevron rotation or heading scroll (see Accessibility Options). separation-of-concerns passes because `DocNavTree` (pure tree rendering and expansion state) and `DocNav` (drawer chrome and fixed top/bottom rows) are split apart, and neither pulls in the host's router beyond the injected `LinkComponent`. unit-test-coverage passes because `docNav.test.tsx` exercises both components across rendering, active/ancestor tracking, expansion persistence, heading scroll, drawer open/close, and accessibility.

