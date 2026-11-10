
- **No children**: When no children are passed, the component renders an empty flex item; per **fills-remaining-space**, it still grows to occupy the leftover vertical space (see viewport-spacer-005 and viewport-spacer-008).
- **Empty className**: An empty-string `className` does not add a trailing space to the root element's class attribute, per **class-composition** (see viewport-spacer-006).
- **Null or undefined children**: When `children` is explicitly `null`, `undefined`, or omitted, the component renders an empty root element with no error, per **render-children** (see viewport-spacer-005).
- **Multiple children**: When multiple children are passed (e.g., within a fragment), the component renders all of them, per **render-children** (see viewport-spacer-007).

