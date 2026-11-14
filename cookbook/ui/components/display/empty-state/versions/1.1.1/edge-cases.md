
- **Null or empty title**: `title` is a required, non-optional prop (see **non-optional-title**); omitting it is a compile-time TypeScript error, so the component never receives a null or undefined title at runtime. A caller passing an empty string or empty fragment renders an empty but valid title area; layout is unaffected.
- **Very long title text**: Component renders title with `text-center` and no truncation constraint; long titles may wrap or overflow depending on container width. Component respects consumer's width context.
- **Long description text**: Description has `max-w-prose` constraint; text wrapping is handled by the prose width, preventing excessive line length.
- **No icon provided**: Icon div is not rendered (conditional render); layout remains centered.
- **All optional props omitted**: Component renders only title and border container, maintaining 160px minimum height.

