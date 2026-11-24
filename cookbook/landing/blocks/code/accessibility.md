
- **Role/Trait**: The component MUST render as a `<pre>` element (preformatted text block). The `<code>` child indicates the content is code.
- **Label requirements**: A parent heading or caption SHOULD precede the code block to provide context; composing recipes are responsible for supplying it, since this ingredient cannot enforce a host's heading structure. The code block itself does not require an `aria-label` if that context is clear from surrounding content.
- **Announce state changes**: Not applicable; this is a static, read-only component with no interactive state changes.
- **Keyboard navigation**: The code block SHOULD be focusable when its rendered width exceeds the container, so the horizontally scrollable region can be reached and scrolled by keyboard (see the axe `scrollable-region-focusable` check). The current React/Web implementation renders a plain `<pre>` with no `tabIndex`, so this is not yet met — see **keyboard-navigable** in Compliance.
- **Minimum tap target**: Not applicable; the code block is read-only and not directly interactive.
- **Semantic structure**: The `<pre><code>` nesting MUST be preserved to indicate preformatted code to assistive technologies.

