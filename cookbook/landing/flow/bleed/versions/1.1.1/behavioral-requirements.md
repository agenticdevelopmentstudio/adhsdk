
- **render-div**: Component MUST render a single `div` element.
- **accept-children**: Component MUST render all content passed via the `children` prop into the `div`.
- **accept-side-prop**: Component MUST accept a `side` prop with string values `"left"` or `"right"`, defaulting to `"right"`.
- **apply-base-class**: Component MUST apply the class `lp-bleed` to the rendered `div`.
- **side-class**: Component MUST apply a class `lp-bleed--{side}` to the rendered `div`, where `{side}` is the value of the `side` prop.
- **accept-class-name-prop**: Component MUST accept an optional `className` prop and append it to the rendered `div`.
- **falsy-class-filter**: Component MUST NOT output empty strings or undefined values in the class list; falsy class names MUST be filtered before joining.
- **side-passthrough**: `side` is typed `'left' | 'right'`; the component performs no runtime check, so a value outside that type (reachable only by a caller that bypasses TypeScript) MUST still render as `lp-bleed--{value}` verbatim. This is unenforced, undefined-by-the-type-system behavior, not a supported input.

