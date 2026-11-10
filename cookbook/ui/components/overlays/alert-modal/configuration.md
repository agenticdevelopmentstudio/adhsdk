
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `open` | `boolean` | — (required) | Controlled visibility, owned by the parent. |
| `title` | `string` | — (required) | Heading line. |
| `description` | `React.ReactNode` | — | Body copy; omitted renders no `DialogDescription`. |
| `tone` | `"info" \| "success" \| "error"` | `"info"` | Sets the leading icon + accent color. |
| `confirmLabel` | `string` | `"OK"` | Primary button label. |
| `confirmVariant` | `Button["variant"]` | `undefined` (→ Button's `"default"`) | Visual variant of the primary button in alert mode when not destructive. |
| `onConfirm` | `() => void` | — (required) | Primary action; also the effective dismiss action in alert mode. |
| `cancelLabel` | `string` | — | Presence switches the component to confirm mode. |
| `onCancel` | `() => void` | — | Cancel action; also the effective dismiss action in confirm mode. |
| `busy` | `boolean` | `false` | Replaces the action buttons with a spinner and blocks dismissal. |
| `dismissible` | `boolean` | `true` | Whether Escape/✕ may close the modal (backdrop/outside clicks never close it, regardless of this prop — see Edge Cases). |
| `keyboard` | `"default" \| "none" \| Partial<Record<string, "confirm" \| "cancel">>` | `"default"` | Keyboard shortcut policy. An explicit map is matched against `KeyboardEvent.key` exactly, case-sensitively. |
| `destructive` | `boolean` | `false` | Forces the error tone visual and forces `keyboard` to behave as `"none"`. |
| `contentClassName` | `string` | `undefined` | Forwarded to `DialogContent` for width/size overrides. |
| `showIcon` | `boolean` | `true` | Whether to show the tone icon in the title. |

