
- **render-trigger-button**: Component MUST render a button element that acts as the disclosure trigger.
- **render-label**: The trigger MUST render the provided `label` prop (defaults to "View source").
- **render-chevron-icon**: The trigger MUST render a chevron-right icon that visually indicates the disclosure state.
- **toggle-on-click**: Clicking the trigger MUST toggle the disclosure between open and closed states.
- **start-closed-by-default**: The disclosure MUST start in the closed state unless the `defaultOpen` prop is explicitly set to `true`.
- **render-source-verbatim**: When open, the component MUST render the `source` prop text exactly as provided, as a plain text node (escaped by the rendering framework), without parsing or transformation. The component MUST NOT inject the source via `innerHTML`, `dangerouslySetInnerHTML`, or any other HTML-parsing API.
- **not-parse-markdown**: The component MUST NOT interpret, parse, or render the source text as markdown or any other format.
- **render-source-in-pre-tag**: The source text MUST be rendered within a `<pre>` element to preserve whitespace and line breaks.
- **rotate-chevron-on-open**: The chevron icon MUST rotate 90 degrees when the disclosure is open and return to its default angle when closed.
- **wrap-text-not-truncate**: Text in the revealed source MUST wrap to the container width rather than truncate.
- **scroll-horizontally-for-long-lines**: When a single unbreakable token (long URL, table rule) exceeds the container width, the source area MUST scroll horizontally without wrapping that token.
- **source-selectable**: The revealed source text MUST be selectable using native text selection, so the reader can copy it.
- **accept-classname-prop**: The component MUST accept and apply a `className` prop to customize styling.
- **accept-html-attributes**: The component MUST accept and pass through standard HTML `div` attributes (via spread `...rest`).
- **set-aria-expanded**: The trigger button MUST set `aria-expanded` to `true` when open and `false` when closed.
- **conditionally-set-aria-controls**: When the disclosure is open, the trigger MUST set `aria-controls` to the panel's ID; when closed, `aria-controls` MUST NOT be set.

