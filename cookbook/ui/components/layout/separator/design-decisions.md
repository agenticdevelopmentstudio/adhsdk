
**Decision**: The separator uses a hairline thickness — the thinnest visually distinct line for the platform — expressed as 1px on web.
**Rationale**: A hairline avoids rendering artifacts and keeps the divider visually unobtrusive across web, mobile, and desktop implementations while letting each platform express it in its own native unit (1px web, 1pt iOS/macOS, 1dp Android) rather than forcing a literal pixel value everywhere.
**Approved**: pending

**Decision**: The component always exposes separator role and orientation to assistive technology, independent of whether the line itself is visually distinguishable.
**Rationale**: Screen reader users should understand the layout's sectional structure even when the divider is subtle or effectively invisible on screen.
**Approved**: pending

**Decision**: The component performs no runtime validation of the orientation value; callers are expected to pass only `"horizontal"` or `"vertical"` (enforced only by the TypeScript type on web).
**Rationale**: Keeps the primitive minimal and avoids runtime overhead for a value that is statically typed at the call site. See `#requirements/orientation-values` for the caller's obligation; the Edge Cases section describes what renders when an unsupported value is passed anyway, and that the component neither falls back nor warns.
**Approved**: pending

**Decision**: Accept the missing unit test for now: no test exercises `separator.tsx`, so `unit-test-coverage` stays `failed` in Compliance.
**Rationale**: The component is a stateless one-element primitive; the five Conformance Test Vectors (`separator-001` to `separator-005`) already define the cases a test would run. The debt is repaid by adding a test that runs those vectors against `separator.tsx`, due the next time the component changes or gains a second consumer.
**Approved**: pending
