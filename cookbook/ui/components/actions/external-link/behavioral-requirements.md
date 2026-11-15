
- **opens-new-tab**: The component MUST set `target="_blank"` so the link opens in a new browsing context.
- **applies-safe-rel**: The component MUST set `rel="noopener noreferrer"` so the opened tab cannot access `window.opener` or leak a referrer.
- **renders-trailing-glyph-by-default**: With no `glyph` prop (default `true`), the component MUST render a trailing `↗` glyph after the children.
- **glyph-is-decorative**: The component MUST mark the `↗` glyph `aria-hidden="true"` so it is not read as part of the link's accessible name.
- **suppresses-glyph-when-false**: Given `glyph={false}`, the component MUST NOT render the `↗` glyph (so a leading icon can carry the affordance).
- **default-deep-link-skin**: The component MUST default to the deep-link grammar — inline layout, a small monospace size that scales with the user's text-size setting, the info-blue token color, no underline, and no line wrapping between the label and glyph. The web class list is in the React/Web Platform Note.
- **focus-ring**: The component MUST show a visible focus ring, in the accent token color, on keyboard focus only.
- **mirrors-glyph-rtl**: In a right-to-left layout the component SHOULD mirror the trailing `↗` glyph (or swap it for a start-pointing equivalent).
- **merges-classname**: The component MUST merge any `className` after the base classes via `cn()`, so a consumer MAY restyle it (font, color, gap) without losing the new-tab/rel behavior.
- **forwards-anchor-props**: The component MUST forward native anchor props (`href`, `onClick`, `title`, `data-*`, …) onto the underlying `<a>`.
- **safe-attrs-not-overridable**: The component MUST apply `target="_blank"` and `rel="noopener noreferrer"` after spreading `...props`, so a caller-supplied `target` or `rel` prop cannot override the safe new-tab contract.

