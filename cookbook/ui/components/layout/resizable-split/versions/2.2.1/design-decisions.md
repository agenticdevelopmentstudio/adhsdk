
**Decision**: Generalize the hand-rolled divider from `status-backend`'s `Dashboard.tsx` (ratio state, `row-resize`, clamp, `localStorage` persistence) into a reusable, token-styled primitive.
**Rationale**: Avoids re-rolling the same divider logic per site; centralizes it as a token-styled component other consumers (e.g. `ListWithDetailsPane`) can reuse.
**Approved**: pending

**Decision**: Keep the ratio internal, seeded from `storageKey` or `defaultRatio`; make persistence opt-in via `storageKey`.
**Rationale**: Keeps the component simple and avoids prop drilling while still supporting stateful, persisted use cases.
**Approved**: pending

**Decision**: Keep the bottom pane mounted while collapsed (`inert`, `height: 0` via `flex-basis`) instead of unmounting it.
**Rationale**: Preserves the bottom pane's internal state across a toggle cycle, enables reveal-to-fit measurement of hidden content, and keeps both endpoints of the `flex-basis` transition always defined.
**Approved**: pending

**Decision**: Offer two divider forms — a minimal 1px seam and an always-visible header bar.
**Rationale**: The seam works best as a divider between independent panes; the header bar anchors the bottom pane's identity and stays visible while collapsed, making clear what the chevron reveals.
**Approved**: pending

**Decision**: Default `expandToContent` to `true` for the header-bar variant and `false` for the seam.
**Rationale**: The header bar already occupies fixed space, so the pane's content size is the more useful secondary signal; the seam has no such anchor, so a user's last manual ratio is the best guess at their preference.
**Approved**: pending

**Decision**: Gate the collapse/expand animation on the app-level `html[data-reduce-motion="on"]` attribute, not the OS `prefers-reduced-motion` media query directly.
**Rationale**: Apps that import the toolkit themes' `accessibility.css` already derive that attribute from the media query; reading the media query directly here too would double-gate.
**Approved**: pending

**Decision**: Suppress the chevron's click when a drag passes over it (reset per pointer-down, tripped after 3px of motion).
**Rationale**: Without this, a small accidental drag while aiming for the chevron would also toggle collapse — the "dancing divider" problem.
**Approved**: pending

