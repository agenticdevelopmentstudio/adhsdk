
- **native-select**: The component MUST render a native HTML `<select>` element, not a custom listbox or dropdown.
- **change-callback**: The component MUST invoke the `onChange` callback with the newly selected value when the user changes the selection.
- **value-reflection**: The component MUST display the `value` prop as the currently selected option in the select element.
- **choice-rendering**: The component MUST render a native `<option>` element for each choice in the `choices` array.
- **choice-label-text**: Each `<option>` element MUST display the `label` property of its corresponding choice.
- **disabled-choices**: The component MUST respect the `disabled` property of individual choices and render disabled options.
- **disabled-control**: The component MUST disable the entire select element when the `disabled` prop is `true`, preventing user interaction.
- **generated-id**: When no `id` prop is provided, the component MUST generate an ID that is unique on the page and stable across renders.
- **provided-id**: When an `id` prop is provided, the component MUST use that ID instead of generating one.
- **label-association**: When a `label` is provided, the component MUST render an HTML `<label>` element with `htmlFor` set to the select's ID, associating the label to the control.
- **wrapper-classname**: The component MUST apply the `className` prop to the wrapper `<div>` when provided (the styled-select primitive diverges; see Platform Notes).
- **hint-display**: When a `hint` prop is provided, the component MUST render it as text content below the select element.
- **chevron-indicator**: The component SHOULD display a visual indicator (such as a chevron icon) to signify that the element is a dropdown control.
- **focus-style**: The component SHOULD apply visual styling to indicate focus when the select has keyboard focus.
- **hint-described-by**: When a `hint` is provided, the component SHOULD associate it with the select via `aria-describedby` so assistive technology announces it as descriptive text for the control.

