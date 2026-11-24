
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | partial | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | passed | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | Internationalization |
| [adc.check.internationalization.text-expansion-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8007859b-a974-5b8a-88f7-162624b0c056) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Statuses rest on `Hero.tsx` and its CSS: the root `<div>` carries no ARIA role even though the `<h1>`/`<p>` it wraps remain correctly semantic (semantic-markup: partial); headline/tagline sizes are `rem`-based and scale with the root font-size dial in `css/base.css` (dynamic-type-support: passed); the default `--lp-ink`/`--lp-ink-dim` tokens against `--lp-ground` compute well above WCAG AA but are host-overridable custom properties (contrast-ratio: partial); the Accessibility Options row above documents the `prefers-reduced-motion` reset (reduced-motion: passed); and `headline`/`tagline` are always host-supplied `ReactNode`s with no strings in source, rendered in flexible `ch`-based containers that tolerate expansion without truncation (no-hardcoded-strings, text-expansion-tolerance: passed). `separation-of-concerns` passes because the component is pure presentation over its props, delegating all layout to `Screen`; `unit-test-coverage` passes on `blocks-close.test.tsx`'s dedicated `Hero` suite, which asserts the mark/headline/tagline/children slots and the `glow` toggle.

