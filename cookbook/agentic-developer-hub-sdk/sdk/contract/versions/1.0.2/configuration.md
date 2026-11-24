
| Option | Type | Default | Description |
|---|---|---|---|
| `ChatConfig.conversationID` | `String` | none (required) | The conversation this configuration wires up |
| `ChatConfig.localParticipantID` | `String` | none (required) | Which participant the local client acts as |
| `ChatConfig.initialParticipants` | `[Participant]` | none (required) | The roster to seed before any `participantJoined` event arrives |
| `ChatConfig.commands` | `[any Command]` | none (required) | The commands `listCommands()` returns |
| `ChatConfig.observingHooks` | `[any ObservingHook]` | none (required) | Fire-and-forget hooks wired to the orchestrator |
| `ChatConfig.gatingHooks` | `[any GatingHook]` | none (required) | Blocking hooks wired to the orchestrator |
| `ChatConfig.permissionStore` | `any PermissionStore` | none (required) | Where permission decisions are remembered |
| `ChatConfig.backend` | `any Backend` | none (required) | The transport the view model drives |
| `ChatConfig.display` | `DisplayConfig` | none (required) | Presentation-affecting flags, see below |
| `DisplayConfig.showAvatars` | `Bool` | none (caller-supplied) | Whether a UI should render participant avatars |
| `DisplayConfig.showReadReceipts` | `Bool` | none (caller-supplied) | Whether a UI should render read receipts |
| `DisplayConfig.showTypingIndicators` | `Bool` | none (caller-supplied) | Whether a UI should render typing indicators |
| `DisplayConfig.maxParticipants` | `Int?` | `nil` | An optional roster cap; enforcement point is not given (see Edge Cases) |
| `DisplayConfig.allowJoining` | `Bool` | none (caller-supplied) | Whether new participants may join |
| `DisplayConfig.allowDeparting` | `Bool` | none (caller-supplied) | Whether participants may leave |
| `DisplayConfig.themeIdentifier` | `String?` | `nil` | An opaque theme selector, uninterpreted by this contract |
| `DisplayConfig.reducedMotion` | `Bool` | none (caller-supplied) | Carries the Reduce Motion accessibility setting into display decisions |
| `ScriptedBackend(script:start:delayBetweenEvents:localIDPrefix:)` | initializer | `start: .immediately`, `delayBetweenEvents: .zero`, `localIDPrefix: "local"` | Fixed-script mode |
| `ScriptedBackend(opening:turn:localIDPrefix:)` | initializer | `opening: []`, `localIDPrefix: "local"` | Turn-based conversation mode; `turn` is required |

