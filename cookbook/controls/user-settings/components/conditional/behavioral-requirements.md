
- **render-children-when-true**: Component MUST render the `children` prop when the `when` prop is `true`.
- **render-fallback-when-false**: Component MUST render the `fallback` prop when the `when` prop is `false`.
- **fallback-defaults-to-null**: Component MUST default `fallback` to `null` when the `fallback` prop is not provided.
- **no-wrapper-element**: Component MUST NOT add a layout or container node around the rendered branch (on React/Web this is a fragment — see Platform Notes).
- **null-children-renders-nothing**: Component MUST render nothing when `children` is `null` or `undefined` and `when` is `true`.
- **falsy-children-renders-value**: Component MUST render a numeric or string `children` value that is falsy (e.g. `0`) when `when` is `true`, rather than treating it as no content. Values that a platform's rendering layer defines as empty content (`true`, `false`, `null`, `undefined`) render nothing.
- **mixed-children-render-in-order**: Component MUST render multiple or mixed-type `children` (arrays, strings, elements, fragments) in the order provided when `when` is `true`.
- **inactive-branch-not-mounted**: When the branch selected by `when` changes to an element of a *different* type (or a differently-identified element) than the one currently rendered, the component MUST unmount the previously rendered branch, discarding its state, and mount the newly selected branch. When the two branches are the same kind of element with the same identity, the platform MAY update the existing instance in place, and its state then survives the toggle (see Edge Cases and Platform Notes).

