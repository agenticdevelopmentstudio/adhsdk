
**Decision**: The @ is embedded as an SVG path (the exact JetBrains Mono weight-400 outline) rather than rendered as live `<text>` with a font dependency.
**Rationale**: This ensures the mark carries its own shape and never depends on the host having the font loaded, guaranteeing consistent rendering across environments. The outline comes from JetBrains Mono, which is licensed under the SIL Open Font License 1.1 (see `references`).
**Approved**: pending

**Decision**: The star is filled with the ADH gold hex literal `#c4a35a` rather than a CSS variable or theme token.
**Rationale**: The registry accent must not dissolve into the host skin and must remain recognizable and distinct regardless of the host's color theme. The same constant is injected as the `--pc-rm-adh-gold` custom property on the root span, which the companion CSS reads for the star's hover/focus bloom (with the hex as a CSS-only fallback), so the SVG fill and the bloom share one source.
**Approved**: pending

**Decision**: The @ glyph is tinted by `fill="currentColor"` (inherited from ancestor CSS `color`), not a dedicated color prop.
**Rationale**: This allows the mark to adapt to the persona's hue or registry house color without requiring a prop, keeping the component's prop surface minimal.
**Approved**: pending

**Decision**: The component is wrapped in React `memo()`.
**Rationale**: The host chat re-renders on every streamed token, but the mark's props are static after mount; memoization prevents unnecessary re-renders as long as callers pass a stable `tip` (see **stable-tip-reference**).
**Approved**: pending

**Decision**: The star uses independent x/y radii (`rx=4.0`, `ry=6.6`) rather than a uniform radius.
**Rationale**: This lets it fill the @ counter's tall-narrow opening without spilling past the glyph into the ring, maintaining visual balance and legibility.
**Approved**: pending

**Decision**: The `tip` is rendered as a plain conditional `<span className="pc-rm-tip">`, styled entirely by the companion `registry-mark.css`, rather than composed from the toolkit's own `@adh-sdk/popover` (`InlinePopover`).
**Rationale**: `InlinePopover` is a JS-driven, click-to-toggle popover (title + description + action links) anchored to interactive content; this mark needs a passive, CSS-only hover/focus tooltip with zero JS and zero added client bundle, so a static credential mark stays static. The two have a different interaction model, trigger, and accessibility timing — sharing one abstraction would bend both out of shape, so they are kept separate on purpose (see `registry-mark.css`).
**Approved**: pending

**Decision**: Every platform port draws the @ glyph and the AI star from the exact geometry defined once in `RegistryMark.tsx` (`AT_GLYPH`, `STAR`, `VIEW`, `AT_CENTER`) — never re-derived or hand-traced independently per platform.
**Rationale**: The glyph outline and the anchor math are precision-sensitive (see **preserve-anchor-geometry**); an independently re-derived path on another platform risks visual drift from the canonical mark. Single-sourcing the path data guarantees a pixel-identical mark everywhere.
**Approved**: pending

**Decision**: Record the absence of `prefers-reduced-motion` gating on the hover/focus bloom and popover transitions as accepted debt for now.
**Rationale**: The companion `registry-mark.css` applies the `filter` transition and the popover fade/slide unconditionally, and Compliance records reduced-motion as failed; whether to gate them in the mark's CSS or leave it to the host is not yet settled.
**Approved**: pending

**Decision**: Record the fixed `11px` popover text, which does not scale with the user's text size, as accepted debt for now.
**Rationale**: `.pc-rm-tip` sets `font-size: 11px` in the companion CSS, and Compliance records dynamic-type support as failed; switching to `rem` units is not yet decided.
**Approved**: pending
