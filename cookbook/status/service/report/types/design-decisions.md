
**Decision**: **server-side-judgement**: Compute verdict, severity, order and completeness on the server; clients format and lay out only.
**Rationale**: Verdict, severity, order and completeness are computed once on the server, so every client (CLI, MCP, agent) reports the same answer and none has to know the rules or keep its own copy in step.
**Approved**: pending

**Decision**: **null-section-for-unread-source**: Give an unread source a null section plus a coverage error, never an empty section.
**Rationale**: An empty list reads as "nothing wrong", so an unread source must not look like one; a null section plus a coverage error says "not read" and keeps an empty list from being mistaken for a healthy source.
**Approved**: pending

**Decision**: **unconfigured-is-not-a-gap**: List a provider with no credentials under `unconfigured` without clearing `complete`.
**Rationale**: A provider with no credentials is a fixed property of a deployment; counting it as a gap would make `complete` permanently false for deployments that never use that provider.
**Approved**: pending

**Decision**: **schema-in-payload**: Carry the version in the payload as a `schema` string.
**Rationale**: A client can refuse a shape it does not know by reading `schema` alone, without parsing the rest, and a breaking change gets a new string instead of silently changing the old one.
**Approved**: pending

