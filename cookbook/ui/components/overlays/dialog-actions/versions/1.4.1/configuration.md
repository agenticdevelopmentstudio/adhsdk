
| Option | Type | Default | Description |
|---|---|---|---|
| `confirmLabel` | `string` | — (required) | Confirm button text. |
| `onConfirm` | `() => void` | — (required) | Confirm handler. |
| `cancelLabel` | `string` | — | Cancel button text; omit to render confirm only. |
| `onCancel` | `() => void` | — | Cancel handler. |
| `confirmVariant` | `Button["variant"]` | `"default"` | Confirm variant when not destructive. |
| `destructive` | `boolean` | `false` | Confirm uses the destructive variant; default focus moves to Cancel. |
| `busy` | `boolean` | `false` | Replace buttons with a status spinner; suppress clicks. |
| `confirmDisabled` | `boolean` | `false` | Disables confirm when not busy (has no effect when `busy` is true). Defaults to false for backward compatibility. |
| `initialFocus` | `"confirm" \| "cancel"` | `destructive ? "cancel" : "confirm"` | Which button gets focus on mount. |
| `focusOnMount` | `boolean` | `true` | When false, do not auto-focus (host focuses its own field). |
| `layout` | `"auto" \| "equal" \| "natural"` | `"auto"` | `auto` lets CSS resolve the rule per alert-and-dialog §Layout; `equal`/`natural` force one shape. |

