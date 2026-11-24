
**Decision**: One frame, host-owned slots — the panel fixes the border, radius,
surface, and header rhythm but leaves every slot (`icon`, `title`, `titleAfter`,
`count`, `center`, `actions`, body) to the host.
**Rationale**: So a stat card and a scrolling list share one component instead
of two bespoke frames.
**Approved**: pending

**Decision**: Shared, exported header height — export
`INFO_PANEL_HEADER_HEIGHT` as a `min-height`, not a fixed height.
**Rationale**: Header alignment across sibling panels on a rail requires a
common baseline; a `min-height` lets headers align while still growing for
taller content.
**Approved**: pending

**Decision**: Two body modes on one prop — `scroll` switches both the outer
flex (`0 0 auto` vs `1 1 0` + `min-h-0`) and the body (`flex-none` vs
`flex-auto overflow-y-auto`).
**Rationale**: So "stat card" and "fill + scroll list" are a single boolean
rather than two components.
**Approved**: pending

**Decision**: `apt-*` tokens over inline hex — the panel uses the central
token utilities instead of the older inline-style + hex-fallback layer.
**Rationale**: The panel themes correctly on every site this way; the
fallback layer was dropped once `@source` guaranteed the utilities exist
everywhere.
**Approved**: pending

**Decision**: `bodyRef` for tail/anchor — expose the scrolling body element
through a ref.
**Rationale**: Lets hosts implement scroll-to-bottom / anchoring without the
panel owning that behavior.
**Approved**: pending

