
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `session` / `viewModel` | ChatSession / any ChatViewModel | required | Backing chat session (web) or view model (iOS) providing messages, active drafts, and status. |
| `localParticipantID` | string | required | (iOS only, constructor parameter) Participant ID used to align bubbles left/right, since `ChatViewModel` itself has no notion of "me". Web derives local/remote through the session `useChatSession` builds from `backend`/`persona`/`user`. |
| `backend` | ChatBackend | required | (web only, `MobileChat` wrapper) Backend passed to `useChatSession` to construct the session. |
| `persona` | ChatParticipant | required | (web only) The remote persona participant. |
| `user` | ChatParticipant | undefined | (web only) The local user participant. |
| `welcomeMessage` | string | undefined | (web only) Optional greeting message seeded into the session. |
| `open` | boolean | required | (web only) Controls surface visibility; the web component is fully prop-controlled. iOS instead exposes `open(animated:)`/`close(animated:)` methods (see Platform Notes). |
| `onClose` | () => void | required | (web only) Invoked when the close button is tapped. iOS has no close button or callback in this source (see Platform Notes). |
| `closeLabel` | string | `"← back"` | (web only) Text of the close button. iOS has no equivalent in this source. |

