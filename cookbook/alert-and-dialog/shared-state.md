
| State | Source | Consumer | Direction | Mechanism |
|---|---|---|---|---|
| open | Caller | Dialog | Down | Prop |
| busy | Caller | Footer buttons / dismissal guard | Down | Prop; replaces buttons with a spinner |
| keyboard policy | Caller (`keyboard`, `destructive`) | Key handler | Down | Prop; `destructive` forces `"none"` |
| confirm / cancel intent | Key handler + buttons | Caller (`onConfirm` / `onCancel`) | Up | Callbacks |

