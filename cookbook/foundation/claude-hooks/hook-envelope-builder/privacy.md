
- **Data collected**: the hook payload, the account name and OAuth login email from the injected closures, and the curated context (home directory, user name, `PATH`, terminal identifiers, host name, operating system and architecture).
- **Storage**: only in memory. `HookEnvCache` holds a process's entire environment, which may include secrets, for three seconds; the built event carries only the curated subset.
- **Transmission**: none by this component; the caller ingests the event.
- **Retention**: a cached entry is no longer served after three seconds (the token walk itself is memoised per pid for 30 seconds inside `ProcessEnv`), but it is removed only when a map grows past 128 entries, so an expired entry, with a whole process environment that may hold secrets, can stay in memory until then.
- **OAuth token**: the token is recovered only to be passed to `accountName`; it is not placed in `hookData` or `context`.

