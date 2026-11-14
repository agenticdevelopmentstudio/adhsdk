
- **render-choices**: The component MUST render each choice in the choices array as a distinct radio button option.
- **maintain-selection-state**: The component MUST maintain and reflect the currently selected value in the `value` prop, rendering that choice's radio input as checked.
- **handle-value-change**: The component MUST invoke the `onChange` callback with the new value when the user selects a different choice.
- **fieldset-root**: The component MUST render a `<fieldset>` element as the root container.
- **legend-label**: When a label prop is provided, the component MUST render it inside a `<legend>` element as the first child of the fieldset.
- **radiogroup-role**: The component MUST render a container element with `role="radiogroup"` that contains all radio button inputs.
- **choice-labels**: The component MUST display a label for each choice; the label MUST be associated with its corresponding radio input.
- **choice-hints**: When a choice has a hint property, the component MUST render that hint adjacent to the choice label.
- **field-hint**: When a hint prop is provided to the component, the component MUST render it as field-level guidance below all choices.
- **disabled-state**: When the disabled prop is true, the component MUST disable all radio inputs and prevent user interaction with the entire group.
- **individual-choice-disable**: When a choice has disabled: true, the component MUST disable only that specific radio input while allowing other choices to remain interactive.
- **custom-classname**: The component MUST accept a className prop and apply it to the root fieldset element, allowing callers to customize appearance.
- **generated-name**: When the name prop is not provided, the component MUST generate a unique name for the radio group using a stable mechanism (e.g., useId).
- **provided-name**: When the name prop is provided, the component MUST use that name for all radio inputs in the group.

