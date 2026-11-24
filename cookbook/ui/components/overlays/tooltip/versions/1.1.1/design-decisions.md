
**Decision**: `TooltipProvider` defaults `delay` to 200ms rather than deferring to Base UI's own default.
**Rationale**: This timing prevents tooltip flicker on quick mouse passes while remaining responsive to intentional hovers; the delay is configurable per provider, letting different contexts trade responsiveness for noise reduction.
**Approved**: pending

**Decision**: The `arrow` prop lets consumers disable the pointer diamond.
**Rationale**: Tooltips on left/right sides can have arrows that visually overlap text content, reducing readability; consumers can disable the arrow for those cases while keeping it enabled for top/bottom (the common case).
**Approved**: pending

**Decision**: Tooltip content renders through a React Portal.
**Rationale**: Ensures tooltips are not clipped by `overflow: hidden` ancestors and always render above sibling content via z-index; see #requirements/not-clipped-by-ancestors.
**Approved**: pending

**Decision**: The Positioner and Popup both render at `z-50`.
**Rationale**: `z-50` is Tailwind's utility convention for floating UI layers, so the tooltip sits above ordinary page content. This component defines no relationship to modal or dialog z-index tiers, so its ordering relative to those overlays is undefined here and must be coordinated by the consuming application.
**Approved**: pending

