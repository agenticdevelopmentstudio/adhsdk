
**Decision**: The separator uses a hairline thickness — the thinnest visually distinct line for the platform — expressed as 1px on web.
**Rationale**: A hairline avoids rendering artifacts and keeps the divider visually unobtrusive across web, mobile, and desktop implementations while letting each platform express it in its own native unit (1px web, 1pt iOS/macOS, 1dp Android) rather than forcing a literal pixel value everywhere.
**Approved**: pending

**Decision**: The component always exposes separator role and orientation to assistive technology, independent of whether the line itself is visually distinguishable.
**Rationale**: Screen reader users should understand the layout's sectional structure even when the divider is subtle or effectively invisible on screen.
**Approved**: pending

**Decision**: The component performs no runtime validation of the orientation value; callers are expected to pass only `"horizontal"` or `"vertical"` (enforced only by the TypeScript type on web).
**Rationale**: Keeps the primitive minimal and avoids runtime overhead for a value that is statically typed at the call site. See **orientation-sync** and the Edge Cases section for the defined appearance when an unsupported value is passed anyway.
**Approved**: pending

