
- **main-root**: Flow MUST render a `<main>` HTML element as its root.
- **programmatic-focus**: Flow MUST set `tabIndex={-1}` on the root element to make it focusable programmatically while excluding it from the default tab order.
- **render-children**: Flow MUST render its `children` prop directly inside the main element.
- **default-class**: Flow MUST apply the `lp-flow` CSS class to the root element.
- **custom-class**: Flow MUST accept an optional `className` prop and append it to the root element's class list when provided.
- **class-merge**: Flow MUST NOT render empty or undefined classes; only non-falsy class names MUST appear in the final class attribute.
- **no-height-or-overflow**: Flow MUST NOT set explicit height or overflow properties on the root element; these are delegated to the parent or document.
- **no-scroll-ownership**: Flow MUST NOT implement scroll behavior itself; scrolling is the responsibility of the containing document or parent.
- **single-main-landmark**: A page MUST render at most one Flow, since each Flow renders a `<main>` element and HTML permits only one visible `main` landmark per document.

