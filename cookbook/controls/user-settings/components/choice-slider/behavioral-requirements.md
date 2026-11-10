
- **accept-choice-array**: Component MUST accept an ordered collection of `Choice<T>` objects, each with a `value` property (string or number) and a `label` property (presentable content, e.g. text or a small view).
- **maintain-value-in-range**: When the `value` prop is passed, the component MUST find the matching choice by value and position the control at its index. If no match is found, it MUST default to the first choice (index 0).
- **fire-change-callback**: When the user changes the selection, the component MUST call the `onChange` callback with the `value` property of the newly selected choice, not the index.
- **display-current-label**: The component MUST display the `label` of the currently selected choice.
- **render-discrete-control**: The component MUST render a native discrete range/slider control with exactly `choices.length` selectable positions (one per choice), so only one choice can be selected at a time.
- **respect-disabled-state**: When the `disabled` prop is true, the control MUST be disabled, preventing user interaction.
- **render-label**: If a `label` prop is provided, the component MUST render it and MUST associate it with the control (e.g. a native label-for-control association) so assistive technology can read it as the control's accessible name.
- **render-hint**: If a `hint` prop is provided, the component MAY render it as additional descriptive text below the control.
- **custom-styling**: The component MAY accept a platform-appropriate styling hook (e.g. a `className` on web) and apply it to the root container alongside the component's required base style classes.
- **custom-id**: If an identifier (e.g. an `id` prop on web) is provided, the component MAY use it for the control. Otherwise, it MUST generate a unique identifier internally.

