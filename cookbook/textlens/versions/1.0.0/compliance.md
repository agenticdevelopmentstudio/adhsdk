
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | passed | Accessibility |
| [adc.check.performance.animation-frame-rate](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9eb9b4fc-2e44-5391-9445-d6e78caa874e) | passed | Performance |
| [adc.check.performance.main-thread-freedom](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/86dd71d6-1ab1-5d59-8c85-b9d469fbae0d) | partial | Performance |

`separation-of-concerns` is passed: colour parsing/resolution (`color.ts`),
the DOM/animation engine (`lens.ts`), and the React binding
(`useTextLens.ts`) are three separate modules with a one-directional import
graph (`useTextLens.ts` → `lens.ts` → `color.ts`) and no circular
dependency. `unit-test-coverage` is partial: `color.test.ts` and
`lens.test.ts` cover `parseColor`, `resolveColor`, and `createLens`'s
splitting, idempotency, reduced-motion gating, start-idempotency, teardown,
and colour-ramp validation, but the package has no test file for
`useTextLens.ts`, its React entry point. `explicit-error-handling` is
passed: `resolveColor` and `resolveRamp` both throw descriptive, traceable
`Error` messages naming the offending value rather than silently falling
back or swallowing bad input. `reduced-motion` is passed:
`respectReducedMotion` defaults to `true` and gates every scheduled frame
behind the `prefers-reduced-motion` media query. `animation-frame-rate` is
passed: the sweep is driven entirely by `requestAnimationFrame`, one frame
scheduled per callback, so it tracks the display's own refresh rate rather
than a fixed-interval timer. `main-thread-freedom` is partial: `apply()`
iterates and writes three inline styles to every measured character span,
on the main thread, once per animation frame, with no windowing or upper
bound on character count — a very long line of split text costs
proportionally more per-frame main-thread work, and the source has no
mechanism to limit or virtualize it.

