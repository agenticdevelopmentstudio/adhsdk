
| Option | Type | Required | Default | Description |
|---|---|---|---|---|
| `items` | `OptionMenuItem[]` | yes | none | The selectable items (`{ value, label }`). |
| `value` | `string \| null` | yes | none | Committed value: an item value, free text (when `allowOther`), or null. |
| `onChange` | `(value: string, meta: { isOther: boolean }) => void` | yes | none | Fired on commit; `isOther` true when from the Other input. |
| `allowOther` | `boolean` | no | `false` | Enables the editable Other row. |
| `otherLabel` | `string` | no | `"Other"` | Label for the Other row. |
| `otherPlaceholder` | `string` | no | none | Placeholder for the Other input. |
| `placeholder` | `string` | no | none | Trigger text when `value` is null. |
| `ariaLabel` | `string` | yes | none | Required; labels the trigger + listbox. |
| `disabled` | `boolean` | no | `false` | Disables the control. |
| `className` | `string` | no | none | Extra classes. |
