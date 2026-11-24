
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | passed | Accessibility |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | partial | Reliability |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

`reduced-motion` is grounded in the `prefers-reduced-motion` media query in `flow.css`, which returns the armed state to opacity 1 and no transform (see **reduced-motion**); `graceful-degradation` is partial because `Reveal.tsx` always renders the resting state when JavaScript never runs, but constructs a new `IntersectionObserver` unconditionally once armed, with no guard for an environment where the API is undefined (see the **No guard for a missing IntersectionObserver** design decision). separation-of-concerns passes because `Reveal.tsx` owns only observation and armed/revealed class-toggling, leaving the fade-and-lift animation and the reduced-motion override to `flow.css` and rendering children as-is. unit-test-coverage is partial: `flow-conformance.test.tsx` covers reveal-001 to reveal-010 with a stubbed `IntersectionObserver`; reveal-011 (reduced-motion) is skipped because it needs a real browser to compute the media query.

