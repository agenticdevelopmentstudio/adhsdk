
- **html-prop**: Component MUST accept a required `html` string containing pre-rendered document markup.
- **unescaped-html-rendering**: Component MUST render the provided HTML string unescaped, so headings, links, and formatting in the markup appear as authored rather than as literal text.
- **prose-typography**: Component MUST apply prose typography to the rendered content — consistent styling for headings, paragraphs, lists, tables, and code blocks.
- **semantic-element-selection**: Component MUST accept an `as` prop that selects the rendered element's tag: `article`, `div`, or `section`.
- **default-article-element**: Component MUST render as an `article` element when `as` is not provided.
- **attribute-passthrough**: Component MUST forward standard HTML attributes it receives (other than `children` and the HTML-rendering mechanism) to the rendered element.
- **class-name-override**: Component MUST accept a `className` prop and merge it with its own typography classes rather than replacing them.
- **code-pseudo-content-removal**: Component MUST render code blocks without generated quote glyphs before or after their content.
- **heading-scroll-offset**: Component MUST give headings a scroll margin so that jumping to an anchor does not hide the heading under fixed UI above the content.
- **children-prop-ignored**: The `children` prop MUST NOT be part of the component's public API; HTML content MUST be supplied exclusively via the `html` prop. This is a compile-time exclusion only (`Omit<..., "children">` on the props type) — the destructured `...rest` still carries a forced-through `children` value at runtime, and spreading it onto the element alongside `dangerouslySetInnerHTML` throws (React allows only one of the two); `children` is not silently dropped.

