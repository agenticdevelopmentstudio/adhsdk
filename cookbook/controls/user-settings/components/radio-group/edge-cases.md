
- **Empty choices array**: When choices is an empty array, the component MUST render a fieldset and radiogroup div but no radio options. This is a valid but typically undesired state; the component does not prevent it. See radio-group-015.
- **Null or undefined label**: When label is null or undefined, the component MUST NOT render a legend element. See radio-group-016.
- **Null or undefined hint**: When the component hint is null or undefined, no field-level hint element MUST be rendered. See radio-group-017.
- **Null or undefined choice hints**: When a choice hint is null or undefined, no hint element MUST be rendered for that choice. See radio-group-018.
- **Value not in choices**: When the value prop does not match any choice's value, no radio input will be checked. This is a valid state representing an unselected group (e.g., during initial render before a default is set); the component does not enforce that value matches a choice. See radio-group-019.
- **Disabled group with onChange**: When disabled=true, the onChange callback MUST NOT be invoked even if the user attempts interaction (disabled by browser). See radio-group-020.
- **Changing choices array mid-interaction**: If the choices array changes while a choice is selected, the component MUST continue to render the current value as checked if it still exists in the new choices array; if the selected value no longer exists, no choice is checked until onChange updates the value. See radio-group-021 and radio-group-022.
- **Type T generics**: The component is generic over T (string | number). Values and onChange callback MUST maintain type consistency; the component does not enforce this at runtime but consumers must ensure type alignment. This is a compile-time constraint with no observable runtime output, so it has no conformance test vector of its own.

