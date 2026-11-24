
- **accept-steps-array**: Component MUST accept a `steps` prop containing an array of `RuleStep` objects.
- **ordered-rendering**: Component MUST render steps in the order provided in the array.
- **render-term-and-detail**: Each step MUST render both a `term` and a `detail` from the `RuleStep` object.
- **accept-react-nodes**: The `term` and `detail` fields MUST accept `ReactNode` values (strings, numbers, booleans, React elements, fragments, or other valid React content).
- **semantic-markup**: Component MUST render as a `<dl>` (definition list) element containing `<dt>` (term) and `<dd>` (detail) child elements.
- **root-class**: Component MUST apply the CSS class `lp-rule` to the root `<dl>` element.
- **keyed-fragment-pairs**: Each term/detail pair MUST render inside a `<Fragment>` keyed by the pair's array index, with no wrapper element around the `<dt>`/`<dd>` pair, so `<dt>` and `<dd>` remain direct children of `<dl>`.

