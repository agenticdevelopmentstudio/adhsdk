
- **Empty children**: Component renders an empty `<div className="lp-cta"></div>` without error. The empty container has no visible size, because the container declares no padding or margin (see Appearance, **Layout**). See **renders-children** and test vector cta-003.
- **Null or undefined children**: Renders the same empty container (React renders nothing for null/undefined); see test vector cta-003.
- **Multiple children**: All children are rendered in document order within the container.
- **Fragment children**: React.Fragment children are unwrapped; their children render in the container.
- **Text node children**: Plain text or string children render as text nodes within the container.
- **Deeply nested children**: Component does not traverse or modify nested component trees.

