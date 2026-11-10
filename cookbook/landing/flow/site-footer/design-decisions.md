
**Decision**: `.lp-site-foot` sets its own background, foreground color, font size, top border, and padding — including dock clearance — directly, rather than delegating any of it to `Wrap` or inheriting it from descendants.
**Rationale**: `Wrap` only constrains content width (see `wrap.md`); the footer needs a full-width band of chrome (ground color, hairline, dimmed ink) independent of that content column, matching the visual treatment of the rest of the page's bands.
**Approved**: pending

**Decision**: Dock clearance (`var(--lp-dock-clear)`) is applied unconditionally to both `.lp-band:last-child`'s bottom padding and `.lp-site-foot`'s bottom padding; on a page that has both a last band and a footer, both pay it.
**Rationale**: `flow.css`'s comment above `.lp-band:last-child` explains that only the last thing in the document — the one thing a fixed host dock can permanently cover, since everything before it can still be scrolled past — strictly needs the clearance: `.lp-site-foot` carries it for a host with a footer, and the `.lp-band:last-child` pair carries it for a host with none. The two rules are not conditioned on each other, so a host with both pays the last band's clearance a second time; the source's own comment accepts that as the safe direction, since the failure it guards against (content trapped under the dock) is worse than one band's worth of extra scroll space.
**Approved**: pending

**Decision**: The component composes `Wrap` non-configurably to constrain content width, the same pattern `Band` uses.
**Rationale**: Keeps horizontal measure consistent with the rest of the page's structural blocks without giving a caller a way to opt out per instance.
**Approved**: pending

**Decision**: `className` merging filters only falsy values (`Boolean` truthiness) and performs no trimming or de-duplication.
**Rationale**: `['lp-site-foot', className].filter(Boolean).join(' ')` is the entire implementation; documenting exactly that behavior — including the whitespace-only string case it does not handle — keeps the contract honest rather than promising validation the source does not do.
**Approved**: pending

