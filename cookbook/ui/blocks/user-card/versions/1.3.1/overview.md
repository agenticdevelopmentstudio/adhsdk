
`UserCard` is a shared profile card component that accepts a `UserCardDto` —
a structural mirror of a backend's `PublicUserProfile`-shaped schema — and
renders whatever fields are present.

All privacy gating is enforced server-side before the DTO is produced. The
component never hides or filters fields on its own; it simply suppresses
empty sections (an empty array is an invisible section). This makes the same
component render correctly for both the public audience (PUBLIC card) and
authenticated hub members (HUB+PUBLIC card with more fields).

Two exports are provided: `UserCard` (the main card) and `UserCardSkeleton`
(a placeholder for the loading state).

**Known consumers**: the Agentic Developer Hub (ADH) uses this component on
its public profile route (`/<slug>`) and in its profile-settings live
preview; ADH's social-links settings editor also imports `PLATFORM_LABELS`
from this module for its own platform picker.

