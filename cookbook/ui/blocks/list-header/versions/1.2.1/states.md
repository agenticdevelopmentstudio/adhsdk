
| State | Appearance change |
|---|---|
| Default | Filter placeholder (`"Filter…"` default) and no value |
| Filter focused | Shared Input focus ring applied |
| Filter with value | Text visible in field, `onChange` called per keystroke |
| No search supplied | Title (if set) and actions render; no search field at all |
| Search grows | Filter field exceeds `max-w-xs` and flexes (`flex-1`), splitting the row's free space evenly with the trailing spacer, when `grow={true}` |

