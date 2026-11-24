
- **render-as-preformatted**: The component MUST render text with preserved whitespace and line breaks exactly as provided in the `text` prop.
- **no-wrap**: The component MUST NOT wrap text to fit the container width; it MUST scroll horizontally when content exceeds the available width.
- **accept-string-prop**: The component MUST accept a single `text` prop of type `string` containing the literal content to display.
- **no-markup-interpretation**: The component MUST NOT interpret, parse, or render any markup (HTML, markdown, JSX, or other syntax) within the `text` prop; the entire string MUST be rendered as literal text.
- **use-monospace-font**: The component MUST render text in a monospace typeface appropriate to the deck's design system.

