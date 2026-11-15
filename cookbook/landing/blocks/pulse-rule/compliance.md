
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | partial | Accessibility |
| [adc.check.performance.animation-frame-rate](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9eb9b4fc-2e44-5391-9445-d6e78caa874e) | passed | Performance |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Reduced motion passes because `blocks.css` removes the animation and sets opacity 1 under `prefers-reduced-motion: reduce`. Semantic markup is partial: the component renders a native `<hr>`, but it does not mark the decorative line as presentation, which `separator-exposure` records as the source's behavior. Animation frame rate passes because the keyframes change only opacity, which the stylesheet comment identifies as compositor-only. No-hardcoded-strings passes because the component renders no text. Separation of concerns passes because `PulseRule.tsx` only emits the element and class while all appearance lives in `blocks.css`. Unit-test coverage passes: `hero-nav.test.tsx` has a passing test for every vector, pulse-rule-001 to pulse-rule-010. The render vectors check the DOM; the stylesheet vectors (pulse-rule-006 to pulse-rule-010) assert the rule text in `blocks.css`, including the `6s` and `0.35` defaults and the `#9a9a9a` fallback, because jsdom computes no animation or gradient.

