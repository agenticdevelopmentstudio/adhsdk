
- **Undefined children**: When children prop is undefined, the component renders an empty button element (no text or content).
- **Null children**: When children prop is null, the component renders an empty button element.
- **Empty string className**: When className is an empty string, it is filtered out during class merging and does not appear in the final class list.
- **Multiple CSS classes in className prop**: When className contains multiple space-separated classes, all classes are preserved in the merged output.
- **Falsy values in className**: When className is `false` or `undefined`, it is filtered out during class merging.
- **Type attribute override**: When a custom `type` prop is passed, it overrides the default `'button'` type.
- **Missing children and empty button**: A button with no children and no text content renders as an empty interactive element; visual appearance depends on CSS (which may apply `::before` or `::after` pseudo-elements or background images).

