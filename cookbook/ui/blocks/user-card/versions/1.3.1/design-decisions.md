
**Decision**: The component renders exactly what the DTO contains; privacy
logic lives entirely in the backend.
**Rationale**: Keeps the component simple and ensures the two card variants
(PUBLIC, HUB+PUBLIC) share one render path.
**Approved**: pending

**Decision**: Use Base UI's `Avatar.Image` (via the shared `AvatarImage`)
instead of a Next.js `<Image />` for the avatar.
**Rationale**: Avatar URLs come from arbitrary user-supplied origins that
can't be enumerated in a consuming Next.js app's image-optimizer allowlist.
`Avatar.Image` gives browser-native lazy loading and a clean fallback via
`AvatarFallback` (the image transitions to error and reveals
`AvatarFallback`) without requiring an allowlist.
**Approved**: pending

**Decision**: `UserCardDto` structurally mirrors the backend's public-profile
schema rather than importing a generated type.
**Rationale**: Keeps `@adh-sdk/ui` free of any API-types
dependency; the structural match is enforced at the call site by the
TypeScript compiler.
**Approved**: pending

**Decision**: Export the `PLATFORM_LABELS` platform-label map from this
module.
**Rationale**: Makes this file the single source of truth for platform
display names, so a consumer's social-links settings editor (e.g. ADH's) can
import the same map instead of duplicating it.
**Approved**: pending

