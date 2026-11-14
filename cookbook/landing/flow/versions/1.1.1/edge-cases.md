
- **No children**: Flow accepts zero children. When rendered without children, it produces an empty `<main tabIndex={-1} className="lp-flow"></main>` element. This is valid and used to establish the structural root even when content is added dynamically.
- **Empty className**: When `className` is an empty string, it MUST be filtered out (see **class-merge**). The resulting `class` attribute MUST be `"lp-flow"` only, not `"lp-flow "`.
- **Multiple class names in className prop**: Flow MUST append the entire `className` prop value unchanged (see **custom-class**). If `className="foo bar baz"`, the result MUST be `class="lp-flow foo bar baz"`.
- **Content taller than the viewport**: Flow itself never scrolls (see **no-scroll-ownership**); when Flow's content overflows the viewport, arrow-key and wheel scrolling moves the nearest scrollable ancestor — normally the document — not the Flow root.
- **Focus behavior on empty Flow**: When rendered with no children and thus no interactive elements, calling `.focus()` on the `<main>` element (see **programmatic-focus**) still succeeds — there is nothing else inside it to receive focus instead.
- **Multiple Flow instances on one page**: Rendering more than one Flow produces more than one `<main>` landmark, which HTML permits only one of (see **single-main-landmark**).

