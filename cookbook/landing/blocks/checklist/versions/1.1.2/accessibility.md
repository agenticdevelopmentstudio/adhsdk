
- Role: The component uses semantic HTML (`<h3>`, `<ul>`, `<li>`, `<span>`) to convey structure; no additional ARIA roles are applied.
- Heading hierarchy: Group headings are always rendered as `<h3>` — a fixed level-3 heading, not configurable by the caller. The containing page MUST place each Checklist instance where a level-3 heading is correct for the surrounding document outline.
- List semantics: Items are wrapped in `<ul>` and `<li>` elements to signal a list to assistive technologies.
- Labels: Item text is directly embedded in the item; there is no explicit labeling mechanism beyond the text itself.
- Differentiate without color: The **soon-class** state is marked by a distinct glyph (`○` vs `✓`, via the `--lp-checklist-mark-soon` / `--lp-checklist-mark` tokens) as well as a dimmer color, so the distinction does not rely on color alone (`packages/web/packages/landing/src/css/blocks.css`).
- **Text equivalent for soon**: The component does not provide a text equivalent for assistive technology beyond the visual glyph change — no ARIA attribute, visually hidden text, or other screen-reader-specific markup accompanies the `soon` state, so a screen reader announces the item's text with no distinction from a non-`soon` item (`Checklist.tsx`).

