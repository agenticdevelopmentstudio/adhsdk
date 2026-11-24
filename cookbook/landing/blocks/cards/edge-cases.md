
- **Conflicting props**: When both `pair` and `trio` are true, an error MUST be thrown synchronously before rendering. This is a caller error, not a silent resolution.
- **Null or undefined children**: Component MUST render successfully with no children or `null` as children; the container remains empty.
- **Empty className**: When `className` is an empty string, it MUST be filtered out and not produce double spaces in the class attribute.
- **Falsy pair/trio**: When `pair` or `trio` are `false`, `undefined`, or not provided, the corresponding class MUST NOT be applied.
- **Boolean prop identity**: Both the conflicting-props check and each variant's class application use strict equality (`=== true`). A falsy value (`0`, `''`, `null`, `undefined`) MUST NOT trigger the conflict error or apply a variant class; a truthy non-boolean value (e.g. `pair={1}`) MUST NOT apply the variant class either — only a literal `true` does.

