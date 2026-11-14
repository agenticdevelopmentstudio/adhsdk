
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | partial | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Font scaling and color contrast are governed by the `.lp-roadmap`/`.lp-eyebrow` stylesheet, which `Roadmap.tsx` does not include, so those two checks cannot be confirmed from the source alone, and semantic-markup is partial because the component renders plain `div`/`span` elements with no incorrect ARIA usage but also no role or label association tying the eyebrow to its children, per the eyebrow's decorative-label design decision. `Roadmap.tsx` is a trivial pure-presentation wrapper over props with no logic beyond the `eyebrow === undefined` branch (separation-of-concerns passed); `blocks-argument.test.tsx` directly exercises both the eyebrow-present and eyebrow-absent cases (unit-test-coverage passed).

