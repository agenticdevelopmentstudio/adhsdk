**Decision**: Compute verdict, severity, order and completeness on the server; clients format and lay out only.
**Rationale**: Verdict, severity, order and completeness are computed once on the server so every client (CLI, MCP, agent) reports the same answer and none has to know the rules.
**Approved**: pending

**Decision**: Give an unread source a null section plus a coverage error, never an empty section.
**Rationale**: An unread source gives a null section plus a coverage error, never an empty section, so an empty list is never mistaken for a healthy source.
**Approved**: pending

**Decision**: List a provider with no credentials under `unconfigured` without clearing `complete`.
**Rationale**: A provider with no credentials is a fixed property of a deployment; counting it as a gap would make `complete` permanently false for deployments that never use that provider.
**Approved**: pending

**Decision**: Carry the version in the payload as a `schema` string.
**Rationale**: The version lives in the payload, so a client can refuse a shape it does not know without parsing the rest.
**Approved**: pending
