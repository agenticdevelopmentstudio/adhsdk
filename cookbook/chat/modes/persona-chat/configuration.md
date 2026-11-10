
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `mode` | `'inline' \| 'three-pane' \| 'mobile'` | (required) | Determines which chat layout to render |
| `backend` | `ChatBackend` | (required) | Chat backend implementation for message exchange |
| `persona` | `ChatParticipant` | (required) | The persona (non-user) participant in the chat |
| `user` | `ChatParticipant` | undefined | Optional user participant; forwarded to the child layout component, which defines what happens when it is omitted |
| `welcomeMessage` | `string` | undefined | Optional greeting message displayed on chat initialization |
| `className` | `string` | undefined | Optional CSS class name; forwarded to the child layout component when `mode` is `'inline'` or `'three-pane'` (`MobileChat` does not accept it) |
| `sizing` | `InlineChatSizing` | undefined | Inline mode only; configures active/inactive sizing and transitions |
| `open` | `boolean` | `false` | Mobile mode only; controls whether the overlay is visible |
| `onClose` | `() => void` | `() => {}` | Mobile mode only; callback when user dismisses the overlay |

