
Not applicable — this is a headless CLI/client, not a visual component; its
only runtime state machine (session token lifecycle: unauthenticated →
authenticated → expired-and-refreshed → logged out) is covered under
Behavioral Requirements above, not as a visual-state table.

