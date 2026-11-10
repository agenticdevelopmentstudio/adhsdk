
- **Undefined props**: When `eyebrow`, `title`, or `children` are `undefined`, the component skips rendering the corresponding element. The container div is always rendered.
- **Null vs. undefined**: The component uses `!== undefined` checks; passing `null` for any prop will cause it to render (e.g., `<span className="lp-eyebrow">{null}</span>`). This may produce an empty element.
- **Empty string or falsy values**: An empty string `""` satisfies the `!== undefined` check and will be rendered, resulting in empty `span` or `h2` elements or no visible content for children.
- **ReactNode types**: The props accept `ReactNode`, allowing strings, numbers, components, fragments, or arrays. All valid ReactNode types are rendered as-is without additional wrapping.

