
| Option | Type | Default | Description |
|---|---|---|---|
| `title` | `React.ReactNode` | — | Left-aligned name of the list (e.g., `"Sites"`). Optional. |
| `search` | `ListHeaderSearch` | — | The controlled filter field. Optional. See below. |
| `search.value` | `string` | — | The current filter text (required if `search` is supplied). |
| `search.onChange` | `(value: string) => void` | — | Called with the new text on every keystroke (required if `search` is supplied). |
| `search.label` | `string` | `"Filter"` | Accessible name for the input. |
| `search.placeholder` | `string` | `"Filter…"` | Placeholder text when empty. |
| `search.autoFocus` | `boolean` | `false` | Focus the field when its `<input>` attaches — re-fires on every remount, unlike the native attribute. Re-renders never steal focus (stable ref identity). |
| `search.grow` | `boolean` | `false` | Let the field flex (`flex-1`) past `max-w-xs` instead of capping there — it shares the row's free space equally with the always-present trailing spacer, so even with no `actions` it fills only about half of the free space, never all of it. See **filter-width-cap**. |
| `actions` | `React.ReactNode` | — | Right-aligned actions (e.g., `+ New` button, Delete). Optional. |
| `ariaLabel` | `string` | — | Accessible name for the toolbar (required). |
| `className` | `string` | — | Extra CSS classes applied to the `ButtonBar` container. |

