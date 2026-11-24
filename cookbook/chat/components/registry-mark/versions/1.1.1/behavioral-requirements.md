
- **render-link**: Component MUST render as a hyperlink (`<a>`) to the persona's `profileUrl` with `target="_blank"` and `rel="noopener noreferrer"`.
- **new-window-disclosure**: Component SHOULD expose (via the required `label` prop, or via additional visually hidden text) that activating the link opens a new tab, since the link always sets `target="_blank"`.
- **accessible-name**: Component MUST set the link's `aria-label` attribute to the `label` prop.
- **render-at-glyph**: Component MUST render an @ symbol using the JetBrains Mono glyph (weight 400), embedded as SVG path data.
- **render-star**: Component MUST render a four-pointed AI star positioned inside the @ counter, filled with hex `#c4a35a`.
- **tint-glyph-with-currentcolor**: Component MUST apply `fill="currentColor"` to the @ glyph, allowing ancestor elements to tint the mark via CSS `color` property.
- **preserve-anchor-geometry**: Component MUST position the @ glyph so its center anchor point aligns with the host's top-right corner (50% X, -50% Y offset via CSS variables).
- **render-optional-popover**: Component MUST conditionally render a popover span when `tip` prop is provided; omit the span when `tip` is undefined.
- **popover-visible-on-focus-or-hover**: Component (via its companion `registry-mark.css`) MUST keep `.pc-rm-tip` visible while the pointer is over the mark or `:focus-visible` is present anywhere within it — including on an interactive element inside the popover — so the popover does not close while a caller tabs into it. The component performs no JS-based focus management of its own; the mechanism is the CSS `:has(:focus-visible)` selector plus a pointer bridge (`.pc-rm-tip::after`).
- **hide-svg-from-accessibility-tree**: Component MUST set `aria-hidden="true"` on the SVG element.
- **support-classname**: Component MUST accept and apply an optional `className` prop, merging it with the required internal class `pc-registry-mark`.
- **memoize-rendering**: Component MUST use React `memo()` to prevent re-renders when props remain unchanged, minimizing re-renders during parent token streaming.
- **stable-tip-reference**: Callers MUST pass a stable `tip` reference (e.g. a module-level constant), not an inline JSX expression, so the component's `memo()` wrapper (see **memoize-rendering**) does not re-render on every streamed token.
- **clip-safe-placement**: The host MUST render the mark as a sibling of the chat view inside a `position: relative` wrapper, outside `.persona-chat` (whose `overflow: hidden` would clip the overhang), or set `clip={false}` on an ancestor `ViewportShell`.

