
The Command Palette is a transient overlay dialog that presents a keyboard-navigable list of grouped commands. A user types in a search field to filter results (filtering is performed by the host, not the component), then navigates and selects items via keyboard or mouse. The palette does not persist state — it closes immediately after an item is selected, and reopening resumes no previous search. It is designed to answer the interaction "I know what I want by name, not by location."

### Props and Types

**`CommandPaletteProps`**

| Prop | Type | Required | Default |
|------|------|----------|---------|
| `open` | `boolean` | required | — |
| `onOpenChange` | `(open: boolean) => void` | required | — |
| `query` | `string` | required | — |
| `onQueryChange` | `(query: string) => void` | required | — |
| `groups` | `CommandGroup[]` | required | — |
| `ariaLabel` | `string` | required | — |
| `placeholder` | `string` | optional | `"Search…"` |
| `loading` | `boolean` | optional | `false` |
| `error` | `string \| null` | optional | `null` |
| `emptyLabel` | `string` | optional | `"No matches"` |
| `footer` | `React.ReactNode` | optional | `undefined` (no footer rendered) |

**`CommandGroup`**

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `id` | `string` | required | |
| `label` | `string` | required | Group heading text; rendered only when `items` is non-empty. |
| `items` | `CommandItem[]` | required | |

**`CommandItem`**

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `id` | `string` | required | |
| `label` | `string` | required | The line the user reads and picks. |
| `description` | `string` | optional | A second, dimmer line. |
| `badge` | `string` | optional | Short leading tag. |
| `hint` | `string` | optional | Right-aligned trailing text. |
| `icon` | `React.ReactNode` | optional | |
| `keywords` | `string` | optional | Matched by `filterCommandItems`; never rendered. |
| `onSelect` | `() => void` | required | Runs on Enter or click; the palette closes immediately after. |

