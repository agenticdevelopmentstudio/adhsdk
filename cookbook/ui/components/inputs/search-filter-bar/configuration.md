
`@adh-sdk/ui/components/search-filter-bar`

| Option | Type | Default | Description |
|---|---|---|---|
| `search` | `SearchFieldConfig` | — (required) | The search field config (see below) |
| `filters` | `FilterSelectConfig[]` | `[]` | Filter selects rendered in the filter row |
| `orientation` | `"stacked" \| "inline"` | `"stacked"` | Filter row under the field, or one wrapping line with it |
| `children` | `React.ReactNode` | — | Extra filter controls, rendered in the row after `filters` |
| `asForm` | `boolean` | `false` | Root on a `<form>` (submit cancelled) rather than a `<div>`, to scope autofill |
| `className` | `string` | — | Extra classes on the `role="search"` root |
| `aria-label` | `string` | — | Accessible name for the `role="search"` landmark |

```ts
interface SearchFieldConfig {
  value: string                       // controlled text
  onChange: (value: string) => void   // called per keystroke
  label: string                       // accessible name (icon-only field)
  placeholder?: string
  onKeyDown?: (e: React.KeyboardEvent<HTMLInputElement>) => void
}

interface FilterSelectOption {
  value: string                       // what the axis stores and reports
  label: string                       // what the option reads as
}

interface FilterSelectConfig {
  name: string                        // stable React key / axis id
  label: string                       // accessible name for the select
  value: string                       // selected value ("" = all-pass)
  options: readonly (string | FilterSelectOption)[]  // bare string = value is the text
  allLabel: string                    // text of the leading all-pass option
  onChange: (value: string) => void   // called with the new value ("" = all-pass)
}

interface SearchFilterBarProps {
  search: SearchFieldConfig
  filters?: FilterSelectConfig[]
  orientation?: "stacked" | "inline"
  children?: React.ReactNode
  asForm?: boolean
  className?: string
  "aria-label"?: string
}
export function SearchFilterBar(props: SearchFilterBarProps): React.ReactElement
```

