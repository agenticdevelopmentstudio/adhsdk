
`ModelRegistry` logs through its `Loggable` logger (subsystem the host bundle id, category `ModelRegistry`), at error level only:

- **A skipped row** (`list-decode-failure`): `Skipping model entry <id>: <decoding error>`. The id is public; the row's JSON is never logged.
- **A refused restore** (`secret-write-rollback`): `Could not restore secret '<field>' of model entry <id>: <error>`. The field name and id are public; no secret value is ever logged.

Every other failure is thrown, or returned as a `ModelTestResult`.

