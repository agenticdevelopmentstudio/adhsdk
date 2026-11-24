
| Option | Type | Default | Description |
|---|---|---|---|
| `items` | `OptionMenuItem[]` | — | The selectable items (`{ value, label }`). |
| `value` | `string \| null` | — | Committed value: an item value, free text (when `allowOther`), or null. |
| `onChange` | `(value: string, meta: { isOther: boolean }) => void` | — | Fired on commit; `isOther` true when from the Other input. |
| `allowOther` | `boolean` | `false` | Enables the editable Other row. |
| `otherLabel` | `string` | `"Other"` | Label for the Other row. |
| `otherPlaceholder` | `string` | — | Placeholder for the Other input. |
| `placeholder` | `string` | — | Trigger text when `value` is null. |
| `ariaLabel` | `string` | — | Required; labels the trigger + listbox. |
| `disabled` | `boolean` | `false` | Disables the control. |
| `className` | `string` | — | Extra classes. |

