
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `AttentionItem.id` | String | fresh UUID string | Identity of the item. |
| `AttentionItem.reference` | `[String: String]` | `[:]` | Free-form pointers (what the item is about), opaque to this file. |
| `AttentionItem.state` | `AttentionState` | `.open` | Starting state. |
| `AttentionItem.createdAt` / `updatedAt` | Date | now | Timestamps taken at construction. |
| `AttentionItem.completedAt` | Date? | `nil` | Completion time, set by a holder. |
| `AttentionAction.id` | String | fresh UUID string | Identity of the action. |
| `AttentionAction.at` | Date | now | When the owner acted. |
| `AttentionAction.messageID` | String? | `nil` | The chat message the action relates to, if any. |

