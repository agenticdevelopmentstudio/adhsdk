
- **Empty string**: If `text` is an empty string, the component MUST render an empty `<pre><code>` block. Neither `.lp-code` nor `.lp-code code` sets a `min-height`, so the block's content box collapses to `0` and only its own padding and border remain — shorter than a populated one-line block (`0.8rem × 1.85` ≈ `1.48rem`) — so a layout shift does occur when `text` transitions between empty and non-empty.
- **Whitespace-only input**: If `text` contains only whitespace (spaces, tabs, newlines), the component MUST render and preserve all whitespace exactly as provided.
- **Very long lines**: If a single line exceeds the container width significantly, the component MUST provide horizontal scrolling without breaking the line.
- **Tabs and special characters**: The component MUST preserve tabs, multiple spaces, and other whitespace characters exactly as provided, rendering per CSS `white-space: pre`. Tab width follows the CSS default `tab-size: 8`, which `lp-code` does not override; a host needing a different width must set `tab-size` explicitly.
- **Unicode and non-ASCII characters**: The component MUST render all valid Unicode characters, including emoji and international text, as literal characters without transformation.

