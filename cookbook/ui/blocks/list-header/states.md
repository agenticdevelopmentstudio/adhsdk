
| State | Appearance change |
|---|---|
| Default | Filter placeholder (`"Filter…"` default) and no value |
| Filter focused | Shared Input focus ring applied |
| Filter with value | Text visible in field, `onChange` called per keystroke |
| No search supplied | Title (if set) and actions render; no search field at all |
| Search grows | With `grow={true}` the filter field loses its `max-w-xs` cap and takes all remaining row width; no trailing spacer renders |

