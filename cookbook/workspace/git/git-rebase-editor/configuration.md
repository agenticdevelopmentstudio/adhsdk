
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `plan` | `GitRebasePlan` | none | The plan to edit, from `init(plan:)`; read back as edited. |
| `onFinish` | `((GitRebasePlan?) -> Void)?` | nil | Called once with the plan for Start Rebase, or nil for Cancel. |
