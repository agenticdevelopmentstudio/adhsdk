
**Decision**: StatCard is pure assembly of `InfoPanel` + `StatRow` + `ExternalLink`,
owning only the body stack and footnote.
**Rationale**: the "figure card with a deep link" shape recurred across the status
board and admin console; centralizing the *arrangement* (not new chrome) keeps every
such card identical and lets the parts evolve independently.
**Approved**: pending

**Decision**: stats are declarative (`stats[]`) with `children` as an escape hatch.
**Rationale**: the common case (a list of label/value figures) is data, not markup;
`children` covers the rare freeform tail (a live error line) without forcing every
caller into imperative rows.
**Approved**: pending

**Decision**: the `link` maps to an `ExternalLink` in the InfoPanel actions slot.
**Rationale**: a stat card almost always deep-links into its source tool (PostHog,
GlitchTip); putting that "{tool} ↗" in the header's actions slot is the established
dashboard grammar and keeps the affordance out of the figure rows.
**Approved**: pending

**Decision**: the footnote is a fixed muted mono 10px qualifier matched to the
StatRow label.
**Rationale**: caveats like "approximate · cookieless" read as chrome around the
figures, so they share the label's micro-caption treatment rather than competing
with the values.
**Approved**: pending

**Decision**: always content-sized (never `scroll`).
**Rationale**: a stat card is a short, fixed set of figures; letting it grow keeps
all figures visible, and callers needing a scrolling list use `InfoPanel` directly.
**Approved**: pending

**Decision**: `actions` is a passthrough slot rendered after the deep link, and host
attributes spread onto the root.
**Rationale**: the fleet status page's monitor card needed a live status word in the
header and `data-*` hooks on the card root; exposing InfoPanel's existing slot and
attribute spread keeps that card on the one StatCard grammar instead of forcing a
site back onto raw InfoPanel + a duplicated footnote.
**Approved**: pending

