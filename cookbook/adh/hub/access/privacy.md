
- **Data collected**: None originated by the module. It reads and writes role, grant and
  assignment records saying which subjects (`customer`, `persona`, `team`) hold which roles at
  which scopes, and `listSubjects` returns each subject's `label`, `email` and `slug`.
- **Storage**: None. The client is a stateless per-call request builder, per
  `no-client-side-cache` and `stateless-module`.
- **Transmission**: Yes. Every call carries a bearer credential attached by the shared
  authentication client, and subject search text travels as the `q` query parameter.
- **Retention**: None. Nothing is held after a response is returned to the caller.

