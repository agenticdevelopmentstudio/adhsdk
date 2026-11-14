
| Option | Type | Default | Description |
|---|---|---|---|
| `options` | `readonly string[]` | — | The selectable entities (e.g. the account's categories or tags). |
| `multiple` | `boolean` | `false` | Discriminates single-value vs. multi-select-set mode. |
| `value` | `string \| null` (single) / `string[]` (multi) | — | The current selection. |
| `onChange` | `(next: string \| null) => void` (single) / `(next: string[]) => void` (multi) | — | Fired with the new selection. |
| `ariaLabel` | `string` | — | Required; labels the trigger, the listbox, and (multi) the chip group. |
| `triggerLabel` | `string` | `"Choose…"` | Trigger text (and the placeholder shown when a single value is null). |
| `inputLabel` | `string` | `ariaLabel` | Accessible label for the filter/add field. |
| `placeholder` | `string` | `ListChooser` default | Placeholder for the filter/add field. |
| `allowCreate` | `boolean` | `true` | Whether text matching no option can be accepted as a new entry. |
| `createLabel` | `(text: string) => string` | `ListChooser` default | Builds the create-row label. |
| `emptyLabel` | `string` | `ListChooser` default | Browser "no matches" message. |
| `emptySelectionLabel` | `string` (multi) | `"Nothing selected yet"` | Hint shown when the set is empty. |
| `selectionPlacement` | `"inline" \| "host"` (multi) | `"inline"` | Whether chips render inline with the trigger or are managed by the host component. |
| `disabled` | `boolean` | `false` | Disables the control. |
| `className` | `string` | — | Extra classes (single: the trigger; multi with inline: the chip+trigger group; multi with host: the trigger). |

### `EntitySelectionChips` (the `selectionPlacement="host"` companion)

| Option | Type | Default | Description |
|---|---|---|---|
| `values` | `readonly string[]` | — | Required; the selected set, in order. |
| `ariaLabel` | `string` | — | Required; names the group (the plural noun the set is of, e.g. "Tags"). |
| `onRemove` | `(value: string) => void` | — | Required; called when a chip's remove control is activated. |
| `emptySelectionLabel` | `string` | — | Hint shown in place of chips when the set is empty. Omit to render nothing at all. |
| `disabled` | `boolean` | `false` | Disables every chip's remove control. |
| `className` | `string` | — | Extra classes on the group. |

