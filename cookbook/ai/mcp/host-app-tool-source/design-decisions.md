
**Decision**: The open-chat-window action is an injected callback, not a direct call into the app's window code.
**Rationale**: The source lives in the macOS feature module but the window-creation code belongs to the host app; a closure keeps the tool source free of app types and testable with a counter, as `HostAppToolSourceTests` does.
**Approved**: pending

**Decision**: `host_open_chat_window` reports success unconditionally.
**Rationale**: The callback returns nothing and cannot throw, so the source has no signal to report a failure. This is the actual behaviour; a port that wants failure reporting changes the callback's type and this contract together.
**Approved**: pending

**Decision**: Both tools are one source with bare names; the host server owns any prefix and the routing.
**Rationale**: The source comment describes it as what the server "used to hard-code, now one source among several", so naming and routing moved to `HostMCPServer`, and this class stays a plain list of two tools.
**Approved**: pending

**Decision**: Arguments and the caller identifier are ignored.
**Rationale**: Neither tool takes parameters or picks a target by proximity, so there is nothing to validate; the unused `caller` is part of the `ChatToolSource` signature, not of this source's needs.
**Approved**: pending

