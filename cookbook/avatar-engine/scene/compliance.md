
| Check | Status | Category |
|---|---|---|
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.performance.main-thread-freedom](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/86dd71d6-1ab1-5d59-8c85-b9d469fbae0d) | passed | Performance |
| [adc.check.performance.animation-frame-rate](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9eb9b4fc-2e44-5391-9445-d6e78caa874e) | partial | Performance |

Every failure path in Scene construction, `compose`, and `crop`/`cropList`
(an unknown variant, an unknown crop, an unresolved colour, a missing
late-bound channel, a self-referential ink cycle) raises a typed,
attributable error rather than swallowing it; the one documented exception
is channel-value-type-mismatch-falls-back, a deliberate default rather than
a swallowed error (explicit-error-handling; see the silent-fallback decision in Design Decisions). Scene delegates path
construction to [adhsdk.ingredient.avatar-engine.path](cookbook:81f8c0bd-ce00-43b3-816e-b63e96baeacc) and matrix arithmetic to
[adhsdk.ingredient.avatar-animation-engine.math](cookbook:471eb7b8-6821-4fd3-ab89-022c56757421), keeping its own responsibility limited to tree
walking, transform composition, and paint/ink resolution
(separation-of-concerns). Both platforms carry a dedicated Scene test
suite (`SceneTests.swift`, `compose.test.ts`) with meaningful per-behavior
assertions covering composition, cropping, channel seeding, and most error
paths (unit-test-coverage: passed). `compose.test.ts` also carries a `conformance vectors` block with one test per vector, 1 to 33, each titled `vector N`; the Apple-only vector 15 wording is exercised on the web through the `body.ink` channel set to `"@body"`, and the traced-to-source vectors (21 to 26 and 28 to 33) build their own scenes or channels to reach the branch. `compose` is a synchronous, O(node-count)-per-call
function with no I/O of any kind (main-thread-freedom). This is the hot
per-frame path a `CADisplayLink`/`requestAnimationFrame` loop calls at a
60fps target, but neither source file measures or enforces a time budget
for a single `compose` call, matching [adhsdk.ingredient.avatar-animation-engine.render.platform-shims](cookbook:39f26055-c002-40fe-81e2-74c0f9c9311d)'s own note on
the same subject (animation-frame-rate: partial).

