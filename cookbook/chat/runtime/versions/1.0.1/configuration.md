
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `ChatConfig.conversationID` | `string` | required | Seeds `conversation.id`. |
| `ChatConfig.localParticipantID` | `string` | required | Identifies which `Participant` is "this" client for `submitMessage`/`markRead`/`setLocalTyping`. |
| `ChatConfig.initialParticipants` | `ReadonlyArray<Participant>` | required | Seeds both the frozen `conversation.participants` and the live `participants` roster. |
| `ChatConfig.commands` | `ReadonlyArray<Command>` | required | Returned verbatim by `listCommands()`. |
| `ChatConfig.observingHooks` | `ReadonlyArray<ObservingHook>` | required | Accepted but never invoked by `DefaultOrchestrator` — see the open question on hook-and-permission-enforcement. |
| `ChatConfig.gatingHooks` | `ReadonlyArray<GatingHook>` | required | Accepted but never invoked by `DefaultOrchestrator` — see the open question on hook-and-permission-enforcement. |
| `ChatConfig.permissionStore` | `PermissionStore` | required | Consulted only via `remember()` inside `respondToPermission`; `decision()` is never called by `DefaultOrchestrator` itself. |
| `ChatConfig.backend` | `Backend` | required | The sole source of `InboundEvent`s and the sole sink for `send`/`setLocalTyping`/`submitWidgetResponse`. |
| `ChatConfig.display` | `DisplayConfig` | required | Stored verbatim as `displayConfig`; never read or branched on internally by these three files (see Accessibility Options and Feature Flags below). |
| `ScriptedBackend` constructor option `localIDPrefix` | `string`, optional | `'local'` | Prefix used to format minted local ids as `<prefix>-<n>`. |

