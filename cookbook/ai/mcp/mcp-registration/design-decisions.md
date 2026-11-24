
**Decision**: The URL, token and pane id are written as `${VARIABLE:-default}` shell-style defaults instead of fixed values.
**Rationale**: The type's doc comment says this lets a shell inside the app, where the variables are set, win over the values baked in at registration time, so one registration keeps working when the port, token or pane changes inside the app.
**Approved**: pending

**Decision**: `isRegistered` matches the port with a substring test and accepts both the literal URL and the `${ADKITCHEN_MCP_URL:-...}` form.
**Rationale**: The doc comment says the check must succeed "literally, or as the `${ADKITCHEN_MCP_URL:-…}` default the command above writes", so a substring test covers both with one comparison; the cost is the leniency listed under Edge Cases.
**Approved**: pending

**Decision**: Every failure of `isRegistered` (missing file, bad JSON, wrong shape) is reported as false with no reason.
**Rationale**: The caller's only use is a "Registered" or "Not registered" status line (`AutomationServerStatus`), for which a missing or unreadable file correctly means "not registered".
**Approved**: pending

**Decision**: The command is built with the loopback host fixed as `127.0.0.1` and plain `http`.
**Rationale**: The endpoint it targets binds only the loopback address and speaks plain HTTP guarded by a bearer token, so the registered URL cannot name any other host.
**Approved**: pending

