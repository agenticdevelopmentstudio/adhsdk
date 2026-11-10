
| State | Source | Consumer | Direction | Mechanism |
|---|---|---|---|---|
| stagedRows (`DraftUser[]`) | AddUsersModal | DataTable, footer Add (enabled state), `onAdd` | Down / Up | Component state + prop; `onAdd` callback |
| entryFields {name, email, phone, note} | AddUsersModal | Entry `Input`s | Down / Up | Component state + input `onChange` |
| discardConfirm open | AddUsersModal | AlertAndDialog (UnsavedChangesAlert) | Down | Boolean state |
| busy | Caller | Footer Add | Down | Prop |
| open | Caller | Dialog | Down | Prop (`open`); `onClose` callback up |

