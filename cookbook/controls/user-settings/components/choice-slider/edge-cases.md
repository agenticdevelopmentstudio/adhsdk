
- **Empty choices array**: `choices: Choice<T>[]` accepts an empty array. The component MUST render an inert slider (`min="0"`, `max="0"`) with an empty caption, MUST NOT throw, and MUST NOT invoke `onChange`. The reference implementation clamps `max` with `Math.max(0, choices.length - 1)`, so it meets this.
- **Single choice**: If `choices.length === 1`, the slider has `max="0"`, preventing any slider movement. The single choice is always selected and displayed. A single choice MUST render as an inert slider.
- **Null or undefined value prop**: When `value` is undefined, `findIndex` returns -1, and `Math.max(0, -1)` yields 0, so the first choice is selected. The component MUST select the first choice in this case.
- **Null or undefined label or hint**: If `label` is falsy, the label element MUST NOT be rendered. If `hint` is falsy, the hint paragraph MUST NOT be rendered.
- **Number vs. string values**: The component compares `c.value === value` without type conversion. If choices contain numeric values but `value` is a string (or vice versa), the comparison fails and the first choice is selected. The component MUST NOT coerce types.
- **onChange called during render**: The `onChange` callback is only called in response to the `input` event on the range element. It MUST NOT be called during render or on prop changes.
