
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `record` | `TRecord` | required | The row as loaded. A new identity re-seeds the draft unless it is dirty. |
| `fields` | `TFields` (a map of `FieldDescriptor`) | required | What is editable and how; typically hoisted to module scope as a constant. |
| `sections` | `TSections` (a list of `SectionSpec`, from `section()`/`dangerZone()`) | required | How the fields are grouped; must cover every declared field exactly once. |
| `onSave` | `(values: TRecord) => void \| Promise<void>` | required | Persists the edited record; also carries the repair pass's write unless `onRepair` is supplied. |
| `onRepair` | `(values: TRecord) => void \| Promise<void>` | `onSave` | Persists a repaired record; use when `onSave` has side effects (closing a pane, navigating) that a system-initiated repair write should not trigger. |
| `onCancel` | `() => void` | `undefined` | Extra work Cancel should do after the draft is discarded. |
| `context` | `TContext` | `undefined` | Whatever the record's field `validate`/`repair` functions need. |
| `readOnly` | `boolean` | `false` | Renders the values without controls, Save bar, repair pass, or (own) contribution to the navigation guard. |
| `validate` | `(values: TRecord) => string \| null` | `undefined` | A cross-field rule no single field descriptor can express; a non-null return blocks Save. |
| `children` | `React.ReactNode` | `undefined` | Rendered after the sections — the usual place for a nested container (a table of rows). |
| `className` | `string` | `undefined` | Extra class names on the outer container `div`. |
| Field option: `label` | `string` | required | Caption above the control (or beside it, for `checkbox`). |
| Field option: `hint` | `React.ReactNode` | `undefined` | Dim helper text below the control; replaced by the error when the field is invalid. |
| Field option: `disabled` | `boolean` | `false` | Locks this control independent of the container's own `readOnly`/`saving` state. |
| Field option: `required` | `boolean` | `false` | Blocks Save while empty and shows `"Required."`; not applicable to `checkbox`. |
| Field option: `placeholder` | `string` | `undefined` | Greyed sample text; `text`, `rdid`, `textarea` only. |
| Field option: `rows` | `number` | `undefined` | `textarea` only. |
| Field option: `options` | `readonly { value, label }[]` | required for `select` | The closed choice list. |
| Field option: `validate` / `repair` | `(value, context) => string \| null` / `(value, context) => value` | `undefined` / `undefined` | Declared together or not at all; `repair` is how the repair pass fixes stored data that fails `validate`. |

