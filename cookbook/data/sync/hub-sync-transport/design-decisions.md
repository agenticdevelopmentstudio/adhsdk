
**Decision**: The transport is a separate framework from the engine and from the hub client.
**Rationale**: The engine stays free of the hub client so a daemon or test can link it alone, and the hub client stays free of the engine. The transport is the one place the two meet.
**Approved**: pending

**Decision**: Coding failures map to `.transport`, not `.invalidResponse`.
**Rationale**: `.invalidResponse` carries a status code, and a body that fails to decode came with a 2xx. Treating it as a transport error makes the engine back off and retry, which is right for a transient proxy page.
**Approved**: pending

