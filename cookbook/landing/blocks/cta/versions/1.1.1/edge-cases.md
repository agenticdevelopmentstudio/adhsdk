
- **Empty children**: Component renders an empty `<div className="lp-cta"></div>` without error. Because `.lp-cta` (`packages/web/packages/landing/src/css/blocks.css`) declares no padding or margin — only `display: flex`, `flex-wrap: wrap`, `gap: 0.75rem`, and `justify-content: center` — and `gap` has no effect with zero or one child, the empty container has no visible size. See **renders-children** and test vector cta-006.
- **Null or undefined children**: Renders empty container (React renders nothing for null/undefined).
- **Multiple children**: All children are rendered in document order within the container.
- **Fragment children**: React.Fragment children are unwrapped; their children render in the container.
- **Text node children**: Plain text or string children render as text nodes within the container.
- **Deeply nested children**: Component does not traverse or modify nested component trees.

