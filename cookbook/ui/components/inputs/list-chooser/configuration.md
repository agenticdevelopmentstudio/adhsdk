
| Option | Type | Default | Description |
|---|---|---|---|
| `items` | `ListChooserItem[]` | — | The selectable items array (`{ value: string, label: string }`). Must not contain duplicate `value` fields. |
| `value` | `string \| null` | — | Committed value: an item's `value`, free text (when `allowCreate`), or null (nothing chosen). This is a controlled prop; changes must come via `onChange`. |
| `onChange` | `(value: string, meta: { isNew: boolean }) => void` | — | Fired when the user accepts a selection. `isNew` is true when the value is typed text, false when it is an item. |
| `allowCreate` | `boolean` | `true` | Whether text matching no item can be accepted as a new entry. When false, only items in the list are acceptable. |
| `ariaLabel` | `string` | — | Required. Labels the trigger button and the listbox for assistive technology. |
| `inputLabel` | `string` | `ariaLabel` | Accessible label for the filter/add field. Falls back to `ariaLabel` if not provided. |
| `placeholder` | `string` | `"Filter or add…"` | Placeholder text shown in the filter field when it is empty. |
| `triggerPlaceholder` | `string` | `"Select…"` | Text shown on the trigger when `value` is null (nothing committed). |
| `okLabel` | `string` | `"OK"` | Accept button label. |
| `cancelLabel` | `string` | `"Cancel"` | Cancel / dismiss button label. |
| `createLabel` | `(text: string) => string` | `` `Add “${text}”` `` | Function that builds the create-row label from the typed text. Example: `(text) => `Add “${text}”`` becomes "Add “React”" when text is "React" |
| `emptyLabel` | `string` | `"No matches"` | Message shown when no item matches the filter and creation is unavailable. |
| `keepOpenOnCommit` | `boolean` | `false` | When true, accepting a selection keeps the popover open for adding multiple entries; Shift+Enter or Esc/Cancel closes. When false, any accept closes the popover. |
| `disabled` | `boolean` | `false` | When true, the trigger is non-interactive and the component cannot be opened. |
| `className` | `string` | — | Extra CSS class(es) applied to the trigger button for custom styling. |

