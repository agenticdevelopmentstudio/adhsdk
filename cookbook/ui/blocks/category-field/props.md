
| Prop | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `label` | `string` | Yes | — | The row's caption, passed to the wrapping `Field`. |
| `noun` | `string` | Yes | — | The singular, lowercase noun used to build the controls' microcopy (e.g. "category"). There is no default; the host must always supply it. |
| `hint` | `React.ReactNode` | No | `undefined` | Optional supporting content passed through to `Field`. |
| `options` | `readonly string[]` | Yes | — | Suggested names for the combobox and entity chooser. A suggestion list, not a closed set — `value` may hold a name that is not in it. |
| `nodes` | `readonly CategoryTreeNode[]` | No | `[]` | The hierarchy (`{ id, name, parentIds }`) that drives breadcrumbs and rename. Omit it and the value renders as the single name it is, with no breadcrumbs. |
| `value` | `string` | Yes | — | The chosen name, or `""` for none. |
| `onChange` | `(next: string) => void` | Yes | — | Called with the new value on a combobox change, an entity-chooser selection, or a rename of the currently selected node. |
| `onRename` | `(node: CategoryTreeNode, nextName: string) => void \| Promise<void>` | No | `undefined` | Renames an existing node from a click on its breadcrumb. May be async. Omit it and breadcrumbs render as static text. |
| `layout` | `"stacked" \| "inline"` | No | Field's own default (`"stacked"`) | Forwarded to `Field` to control label positioning. |
| `disabled` | `boolean` | No | `false` | Disables the combobox, the entity chooser, and breadcrumb rename buttons. |
| `className` | `string` | No | `undefined` | Forwarded to `Field` for custom styling. |

`onRenamed` is not a prop of CategoryField — it is `CategoryRenameDialog`'s own callback (see [adhsdk.ingredient.ui.blocks.category-rename-dialog](cookbook:526da033-2f0d-4bd7-b2c2-99faba4783a3)), which CategoryField wires internally to call `onChange` only when the renamed node is the selected one.

