
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | failed | Best Practices |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | passed | Reliability |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | Reliability |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | failed | Accessibility |

Statuses rest on the source: identity (SVG/pose data) and behavior (this
engine) are cleanly split — no avatar's anatomy or mood names are baked into
`engine.ts`/`arbitration.ts`/`pose.ts` — so separation-of-concerns passes.
`engine.test.ts` is an explicit smoke test only (its own comment: "the
engine is a GSAP-driven hook — its motion is verified in-app, it can't be
asserted headless"); it checks the exported surface and that
`DEFAULT_TUNING` has 13 numeric fields, but omits `swayCalm`/`swayLively`
from that check and asserts none of the arbitration, blink, ladder, gaze, or
pose behavior itself, so unit-test-coverage is partial rather than passed.
No file in this source contains a `try`/`catch`, a validation guard on
`Pose`/`Tuning` shape, or a check on MorphSVG point counts, so
explicit-error-handling fails outright (see **morph-point-count-validation**
and **pose-shape-validation**). Every timer and tween is paired with a
teardown (cleared timeouts/intervals, killed GSAP animations, removed event
listeners) across `arbitration.ts`, `gaze.ts`, `idleLife.ts`, and
`engine.ts`'s own unmount effect, so fault-tolerance passes. Every channel
on `AvatarRig` is optional and every dependent effect checks for its
presence before acting, so an avatar wiring only a subset of channels still
runs without error — graceful-degradation passes. A grep of the whole
package for `matchMedia`/`reduce`/`prefers`/`contrast` finds nothing, while
several loops (breathing, sway, blink, wander) run unconditionally and
indefinitely, so reduced-motion fails (see the Accessibility Options
section above). Accessibility categories beyond reduced-motion,
internationalization, security, and privacy checks are not listed here
because this engine has no visible surface, no user-facing strings, no
authentication/credential handling, and no data collection for those
categories to apply to (see the Accessibility, Localization, and Privacy
sections above).

