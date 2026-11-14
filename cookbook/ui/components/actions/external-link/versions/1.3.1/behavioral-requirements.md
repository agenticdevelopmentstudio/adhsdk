
- **opens-new-tab**: The component MUST set `target="_blank"` so the link opens in a new browsing context.
- **applies-safe-rel**: The component MUST set `rel="noopener noreferrer"` so the opened tab cannot access `window.opener` or leak a referrer.
- **renders-trailing-glyph-by-default**: With no `glyph` prop (default `true`), the component MUST render a trailing `↗` glyph after the children.
- **glyph-is-decorative**: The component MUST mark the `↗` glyph `aria-hidden="true"` so it is not read as part of the link's accessible name.
- **suppresses-glyph-when-false**: Given `glyph={false}`, the component MUST NOT render the `↗` glyph (so a leading icon can carry the affordance).
- **default-deep-link-skin**: The component MUST default to the deep-link grammar — inline-flex, `font-mono`, `text-[11px]`, `text-apt-blue`, no underline, `whitespace-nowrap`.
- **focus-ring**: The component MUST show a visible focus ring on keyboard focus (`focus-visible:ring-2 focus-visible:ring-apt-gold/40`).
- **merges-classname**: The component MUST merge any `className` after the base classes via `cn()`, so a consumer MAY restyle it (font, color, gap) without losing the new-tab/rel behavior.
- **forwards-anchor-props**: The component MUST forward native anchor props (`href`, `onClick`, `title`, `data-*`, …) onto the underlying `<a>`.
- **safe-attrs-not-overridable**: The component MUST apply `target="_blank"` and `rel="noopener noreferrer"` after spreading `...props`, so a caller-supplied `target` or `rel` prop cannot override the safe new-tab contract.

