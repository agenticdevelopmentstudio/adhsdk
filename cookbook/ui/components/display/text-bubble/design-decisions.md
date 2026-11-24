
**Decision**: The text renders plain (crawlable, selectable) first and is only imperatively split into per-glyph spans while `active`; an off-screen full-text copy plus `aria-hidden` on the visible spans keeps screen readers reading the whole phrase, and cleanup restores the plain text.
**Rationale**: The effect never carries meaning, so turning it off (or restoring it on cleanup) loses nothing — decorative-first keeps the component accessible by construction rather than by afterthought.
**Approved**: pending

**Decision**: The lens centre interpolates along the polyline of glyph centres (in reading order) instead of moving in raw screen space.
**Rationale**: Following the text lets the lens sweep to the next line at each wrap and stay visually locked to the glyphs regardless of layout.
**Approved**: pending

**Decision**: Glyph positions are measured with `offsetLeft`/`offsetTop` (layout space) rather than `getBoundingClientRect`.
**Rationale**: Layout-space measurement ignores an ancestor entrance/scale transform, so the lens stays aligned while the host is still animating in.
**Approved**: pending

**Decision**: Whole words are wrapped in `inline-block; nowrap` spans, with the inter-word whitespace left as plain text.
**Rationale**: Splitting bare characters would let a line break occur mid-word; wrapping at the word level prevents that while still allowing per-character animation inside each word.
**Approved**: pending

**Decision**: Text containing cursive-joining scripts (see **skip-cursive-scripts**) is left rendered normally rather than split into per-character spans.
**Rationale**: Per-character spans break cursive joining, so scripts that join (Arabic, Syriac, …) would be mis-shaped if split.
**Approved**: pending

**Decision**: Glyphs beyond the (squared) lens radius are skipped without a `sqrt`, and `will-change` is toggled on/off per glyph as it enters/leaves the lens.
**Rationale**: Culling cheaply and promoting only the handful of in-lens glyphs keeps a long string's compositing cost low.
**Approved**: pending

**Decision**: The component does not itself detect `prefers-reduced-motion`; hosts control the effect entirely through the `active` prop, which they MAY gate on that media query.
**Rationale**: The lens is purely decorative and never carries information, so whether to suppress it under reduced motion is a per-host UX choice; keeping the check out of the component avoids duplicating logic an app may already centralize in one place.
**Approved**: pending

