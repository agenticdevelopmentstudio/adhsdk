
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | Internationalization |
| [adc.check.internationalization.text-expansion-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8007859b-a974-5b8a-88f7-162624b0c056) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`semantic-markup` and `no-hardcoded-strings` rest on `FlowHero.tsx` rendering `<div>`/`<h1>`/`<p>` with every string passed through as a ReactNode prop, not a literal in source; `text-expansion-tolerance` rests on `flow.css` sizing the headline/sub/meta with `rem`/`ch`/`clamp()`, `text-wrap: balance`/`pretty`, and no truncation or overflow rule; `dynamic-type-support` is `partial` because the CSS uses relative (`rem`) units, which scale with a browser's font-size setting, but the source shows no explicit platform Dynamic Type integration; `contrast-ratio` is `partial` because the actual foreground/background pairing comes from host-supplied `--lp-ink*`/`--lp-hero-wash` tokens the source cannot verify. `separation-of-concerns` is `passed` because the component is pure layout over props with no business logic; `unit-test-coverage` is `passed` because `flow.test.tsx` renders `FlowHero` directly.

