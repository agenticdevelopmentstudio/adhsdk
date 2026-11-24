
- **Empty choices array**: `choices: Choice<T>[]` accepts an empty array and the source adds no guard against it. An implementation MUST render an inert range input (`min="0"`, `max="0"`) with an empty caption for an empty `choices` array, MUST NOT throw, and MUST NOT invoke `onChange`.
- **Single choice**: If `choices.length === 1`, the range input has `max="0"`, preventing any slider movement. The single choice is always selected and displayed. This is valid but may confuse users; no error state defined.
- **Null or undefined value prop**: When `value` is undefined, `findIndex` returns -1, and `Math.max(0, -1)` yields 0, selecting the first choice by default. This is a safe fallback.
- **Null or undefined label or hint**: If `label` is falsy, the label element is not rendered (conditional render). If `hint` is falsy, hint paragraph is not rendered. This is correct.
- **Number vs. string values**: The component compares `c.value === value` without type conversion. If choices contain numeric values but `value` is a string (or vice versa), the comparison fails and the first choice is selected. No type coercion is performed.
- **onChange called during render**: The `onChange` callback is only called in response to the `input` event on the range element. It is not called during render or on prop changes.

