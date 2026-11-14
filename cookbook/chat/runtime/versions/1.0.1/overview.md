
The chat coordinator runtime is the headless reference implementation of the
cross-platform chat contract's `Orchestrator`/`ChatViewModel` surface. It has
no rendered UI of its own — a host layer (`useChatSession` or a similar hook,
outside the scope of this recipe) constructs it and lets UI components read
its state and call its methods. It is three cooperating pieces:

- **`DefaultOrchestrator`** (`DefaultOrchestrator.ts`) — the reference
  `Orchestrator` implementation. It consumes an injected `Backend`'s
  `inboundEvents` stream, maintains every field `ChatViewModel` declares
  (`messages`, `participants`, `activeDrafts`, `activeCommands`,
  `readMarkers`, `typingParticipants`, `pendingWidgets`,
  `pendingPermissions`), and fans out a `ChatUpdate` to every registered
  `ChatStateObserver` after each state-changing event or method call.
- **`InMemoryPermissionStore`** (`InMemoryPermissionStore.ts`) — a
  process-local `PermissionStore`. It remembers only `allowAlways`/
  `denyAlways` decisions (single-use `*Once` decisions are never persisted)
  and falls back to a permission's own `defaultDecision` when nothing is
  remembered.
- **`ScriptedBackend`** (`ScriptedBackend.ts`) — a test-double `Backend`
  driven entirely by explicit `emit()` calls. It records every outbound call
  (`send`/`setLocalTyping`/`submitWidgetResponse`) so a test can assert on
  them, and exposes `inboundEvents` as a hand-rolled async iterable backed by
  a queue and a set of parked waiters.

`DefaultOrchestrator` is the single consumer of whatever `Backend` it is
constructed with (stated in `Backend.ts`'s own doc comment); it never
multiplexes one backend to more than one orchestrator itself. Ports of this
runtime replace `Backend`/`PermissionStore` with a networked or persisted
implementation without changing `DefaultOrchestrator`'s contract.

