
- **Layout**: Centered vertical stack composition, with child elements constrained within a `Wrap` container (see **render-order**)
- **Background**: `var(--lp-hero-wash, var(--lp-ground, #101010))` on `.lp-hero-flow` — a hero wash is the single most site-specific surface on the page, so the component sets no default beyond the page ground token
- **Typography**:
  - Headline: `<h1>` semantic heading
  - Subheading: `<p>` with class `lp-hero-sub`
  - Metadata: `<p>` with class `lp-hero-meta`, uppercased by stylesheet
- **Spacing**: Managed by CSS classes (`lp-hero-actions`, `lp-hero-shot`)
- **Mark container**: Rendered as provided (no styling applied by component)

