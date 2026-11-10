
- **Empty steps array**: When `steps` is an empty array, the component MUST render an empty `<dl>` element (no child elements).
- **Single step**: When `steps` contains one step, the component MUST render one `<dt>` and one `<dd>` pair.
- **Large step arrays**: The component has no configured limit on step count; rendering is a single pass over the array, so cost scales with array length. No specific size threshold is benchmarked or asserted as a requirement.
- **Null or undefined steps**: `steps` is a required `RuleStep[]` prop, so the type contract excludes `null` and `undefined` and the component adds no runtime guard. A translation with a weaker type system (or one accepting untyped JSON) MUST treat a missing array as empty rather than crash.
- **Null or undefined term/detail**: If a step's `term` or `detail` is `null` or `undefined`, React renders nothing for that content; the corresponding `<dt>` or `<dd>` element is rendered but empty.
- **Non-ReactNode values**: Numbers and booleans are valid `ReactNode` values — a number renders as text, a boolean renders nothing. A plain object is not a valid `ReactNode`; passing one as `term` or `detail` causes React to throw ("Objects are not valid as a React child") when the component renders.

