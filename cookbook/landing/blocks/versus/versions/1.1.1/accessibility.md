
- **Role**: Each side is a div container; title is an h3 heading; lede is a paragraph; points are a list.
- **Semantic structure**: Title renders as a fixed h3; this assumes Versus is placed under a page section already at h2 (or otherwise one level above), so the heading sequence isn't skipped. The component does not offer a configurable heading level. Assistive technologies announce list structure for points.
- **Label requirements**: Titles are read as headings; lede provides context; bullet points are announced as list items.
- **Non-visual distinction**: The component provides no text label, `aria-label`, or semantic-role difference between "us" and "them" beyond the differing marker class (see **distinguish-sides**) — the distinction is visual only (border, background, glow). A non-visual cue, if needed, is the surrounding page's responsibility, not this component's; see **Differentiate Without Color** below.
- **Minimum tap target**: Panels are containers; no interactive tap targets within this component itself.

