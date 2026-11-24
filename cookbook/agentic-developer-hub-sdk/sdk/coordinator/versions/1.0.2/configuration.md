
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `personaSlug` | `String` | *(required)* | Persona to converse with; adh resolves everything else — display name, avatar, model, system prompt — from this slug. |
| `baseURL` | `URL` | *(required)* | Root of the adh chat API, e.g. `https://adh.example.com/api`; `chat/conversations` and `chat/conversations/<id>/messages` are appended to it. |
| `authorize` | `Authorize` (`@Sendable (URLRequest) async throws -> AuthorizedResponse`) | *(required)* | Credential-attaching transport injected by the host; the coordinator never constructs or stores credentials itself. |
| `model` | `String?` | `nil` | Overrides the persona's configured model for the conversation this coordinator creates; omitted from the request entirely when `nil`. |
| `participantID` | `String?` | `nil` (resolves to `personaSlug`) | Identifies the persona in every `InboundEvent` the coordinator emits. |
| `onStatus` | `(@Sendable (TurnStatus?) -> Void)?` | `nil` | Receives turn-phase transitions in addition to the `statusChanged` event; cleared with `nil` when a turn ends. |
| `session` (via `urlSessionAuthorize(session:)`) | `URLSession` | `.shared` | Underlying session used only when a host opts into the coordinator's own default `Authorize` factory instead of supplying one. |

