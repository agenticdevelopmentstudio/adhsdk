
- **Data collected**: Process ids, launch directories, parent pids, session ids, arguments and the environment of the current user's `claude` processes. The environment is used for one value only (`CLAUDE_CONFIG_DIR`); the type reads no token itself.
- **Storage**: None. Nothing is written or cached; results are returned to the caller.
- **Transmission**: This component does not transmit anything. The pid it recovers is later used by callers to read an environment that decides the account an event is billed to, which is why an ambiguous directory returns nil.
- **Retention**: None.

