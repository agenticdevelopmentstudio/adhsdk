
**Decision**: The entry names a `headersHelper` that runs `adhd mcp headers` instead of a baked-in token.
**Rationale**: No token is then ever written into `~/.claude.json`, a shell history or a pane's environment, and adhd can rotate it without the user registering again.
**Approved**: pending

**Decision**: Each channel has its own server name and fixed port (`adhd-dev` on 22871, `adhd` on 22850).
**Rationale**: A dev build never takes over the release entry, and with a fixed port the registration never goes stale, so the environment-default URL form the Kitchen used is no longer needed.
**Approved**: pending

**Decision**: `isRegistered` compares the `url` for equality.
**Rationale**: The port is fixed per channel, so equality is exact where the old substring test, needed for the `${ADKITCHEN_MCP_URL:-…}` form, matched longer URLs too.
**Approved**: pending

**Decision**: Every failure of `isRegistered` (missing file, bad JSON, wrong shape) is reported as false with no reason.
**Rationale**: The caller's only use is a "Registered" or "Not registered" status line (`AutomationServerStatus`), for which a missing or unreadable file correctly means "not registered".
**Approved**: pending

**Decision**: The URL is fixed as `http://127.0.0.1`.
**Rationale**: The endpoint binds only the loopback address and speaks plain HTTP guarded by a bearer token, so the registered URL cannot name any other host.
**Approved**: pending
