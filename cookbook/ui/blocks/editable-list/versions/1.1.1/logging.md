
Subsystem: `adhsdk.ui.blocks` | Category: `EditableList`

| Event | Level | Message |
|-------|-------|---------|
| Render | debug | `EditableList rendered: ${ariaLabel}, rows: ${list.rows.length}, filtered: ${list.filtered}, selected: ${list.selectedIds.size}` |
| Error | error | `EditableList error: ${errorMessage(error)}, ariaLabel: ${ariaLabel}, rows: ${list.allRows.length}` |
| Column resize | debug | `EditableList column resized: column=${column.key}, stored under key=${columnWidthsKey}` |
| Sort change | debug | `EditableList sort changed: key=${sort.key}, direction=${sort.direction}` |
| Selection change | debug | `EditableList selection changed: selected=${list.selectedIds.size}, hidden=${hiddenSelected}` |

`error` is typed `unknown`. `errorMessage()` is the same coercion the component's own render path uses (`err instanceof Error ? err.message : String(err)`) — an `Error`'s `.message` for a real error, `String(err)` for anything else thrown, never a raw property access that would fail on a non-Error value.

