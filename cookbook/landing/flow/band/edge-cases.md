
- **Multiple classes**: When `seam`, `tone`, and `className` are all provided, all resulting classes (`lp-band`, `lp-band--{tone}`, `lp-band--seam`, and custom class) MUST be present in the section's class list.
- **Empty children**: Band MUST accept empty or no children and render without error. The `Wrap` component determines rendering behavior for empty content.
- **Falsy className**: If `className` is an empty string or falsy, it MUST NOT add extra spaces or broken classes to the section; filtering MUST remove it from the class list.
- **Missing id**: If `id` is not provided, Band MUST render the section without an `id` attribute rather than an empty or literal `"undefined"` value.
- **Tone with seam combinations**: All three tones (dark, soft, paper) MUST work with both `seam: true` and `seam: false` without conflict. On `tone="paper"`, the `seam` prop controls the top edge only; the bottom cut always applies — see **paper-cuts-foot**.
- **First band on a page**: `seam` defaults to `true`, so a band with no preceding sibling still pulls itself upward by `--lp-seam` with nothing behind it to reveal. Band does not detect this case. The caller SHOULD pass `seam={false}` for the first band under a hero that already ends on an angle, and for any band whose neighbor above shares the same tone (an invisible seam between identical grounds still costs the overlap).

