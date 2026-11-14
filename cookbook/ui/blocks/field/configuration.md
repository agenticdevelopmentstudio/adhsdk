
| Option | Type | Default | Description |
|---|---|---|---|
| `label` | `ReactNode` | — (required) | The caption text, rendered uppercase-mono before the control (above when stacked, beside when inline). |
| `children` | `ReactNode` | — (required) | The control (e.g. `Input`/`Select`/`Switch`/`Textarea`). |
| `hint` | `ReactNode` | — | Dim-mono helper line below the control; shown only when `error` is unset. |
| `error` | `ReactNode` | — | Red-mono inline error; when set, replaces `hint` in the same slot. |
| `errorId` | `string` | — | Names the error line for a control that points `aria-describedby` at it. |
| `layout` | `"stacked" \| "inline"` | `"stacked"` | Caption above the control (default) or beside it in a fixed-width right-aligned column for grouped rows. |
| `className` | `string` | — | Extra classes merged onto the root `Label` via `cn()`. |
| `FIELD_LABEL_GROUP_CLASS` | exported `string` constant | `"[--apt-field-label-w:6.5rem]"` | Public export. A wrapper applies it to set `--apt-field-label-w` to the one label-column width every inline group in the family shares. See Appearance. |
