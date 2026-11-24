
| State | Source | Consumer | Direction | Mechanism |
|---|---|---|---|---|
| `title` | Caller | Group heading (`<h3>`) | Down | Prop |
| `trailing` | Caller | Title-row accessory slot | Down | Prop (optional) |
| `children` (Fields) | Caller | Stacked group body | Down | Prop |
| Field values / validation | Owning form (outside the group) | The `Field` controls | — | Not owned by `FieldGroup` — it is pure layout |

`FieldGroup` holds no state of its own; it is a stateless layout wrapper, so all
form state flows through the `Field` controls the caller nests, not through the
group.

