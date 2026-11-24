
Not a runtime-configurable component — `FacetMenu` is controlled entirely through its props:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `label` | `string` | — (required) | Text shown in the trigger, before the count |
| `options` | `string[]` | — (required) | The full set of selectable values, in render order |
| `selected` | `Set<string>` | — (required) | The currently checked values; owned by the host |
| `onChange` | `(next: Set<string>) => void` | — (required) | Invoked with the updated selection on every toggle, "All", or "None" |
| `labelOf` | `(value: string) => string` | identity (value shown as-is) | Optional transform from an option value to its display label |

