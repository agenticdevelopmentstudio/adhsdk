
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| label | ReactNode | undefined | Optional label text rendered in a legend element |
| hint | ReactNode | undefined | Optional field-level guidance text rendered below choices |
| value | T (string \| number) | required | The currently selected choice value; SHOULD match one of the choice values so that choice renders as checked. If it does not match any choice, no radio input is checked (see Edge Cases: Value not in choices). |
| onChange | (value: T) => void | required | Callback invoked when the user selects a different choice |
| choices | `Choice<T>[]` | required | Array of choice objects, each with value, label, and optional disabled and hint properties |
| disabled | boolean | false | When true, disables all radio inputs and the fieldset |
| className | string | undefined | Optional CSS class string applied to the root fieldset element |
| name | string | undefined | Optional name attribute for all radio inputs; if omitted, a unique name is generated via useId |

