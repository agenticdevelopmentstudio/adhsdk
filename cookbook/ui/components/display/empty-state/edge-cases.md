
- **Null or empty title**: `title` is a required, non-optional prop (see **title**); omitting it is a compile-time TypeScript error, so the component never receives a null or undefined title at runtime. A caller passing an empty string or empty fragment renders an empty but valid title area; layout is unaffected.
- **Very long title text**: Component renders title with `text-center` and no truncation constraint; the title wraps at whitespace within the container's width, and an unbroken string longer than the container can overflow because no `break-words` is applied.
- **Long description text**: Description has `max-w-prose` constraint; text wrapping is handled by the prose width, preventing excessive line length.
- **No icon provided**: Icon div is not rendered (conditional render); layout remains centered.
- **All optional props omitted**: Component renders only title and border container, maintaining 160px minimum height.
- **Falsy slot values**: `icon`, `description` and `action` are truthiness-checked, not null-checked. Passing `0` renders a stray "0" (React renders the number), and passing `""` renders nothing and no wrapper.
- **Block-level content**: The title and description are wrapped in `<p>` elements, so passing a block element (`<div>`, `<ul>`) as either produces invalid HTML nesting. Consumers SHOULD pass inline content.
