
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `resetKey` | `unknown` (pass a primitive) | `undefined` | Value identifying which rows are currently visible (page number, search string, active filters). Whenever it changes by `Object.is`, `selectedIds` is cleared. See **reset-on-reset-key-change**. |
| `selectLabel` | `string` | `"Select"` (`batch_select.select`) | Label the `BatchSelectButton` displays while batch mode is inactive. |
| `doneLabel` | `string` | `"Done"` (`batch_select.done`) | Label the `BatchSelectButton` displays while batch mode is active. |

