
**Decision**: Both the fill (`background: currentColor`) and the glow
(`color-mix` of `currentColor`) derive from the tone's text color, so a single
`text-apt-*` class recolors the entire dot.
**Rationale**: This avoids a parallel set of per-tone shadow classes that
could drift out of sync with the fill.
**Approved**: pending

**Decision**: `size` is a raw px number rather than a `sm/md/lg` token.
**Rationale**: A status dot must optically match mono text at whatever size it
appears next to (row label, hero figure, inline word), so the caller tunes it
to the neighbouring text.
**Approved**: pending

**Decision**: The glow radius floors at 6 px (`max(6, round(size*0.55))`).
**Rationale**: This keeps small dots from losing their halo entirely,
preserving the "soft light" read even at `size={8}`.
**Approved**: pending

**Decision**: The dot is decorative (`aria-hidden`) by default and becomes
`role="img"` only when given a `label`.
**Rationale**: This matches the common case where visible text already
carries the status and a second announcement would be noise.
**Approved**: pending

