
Tool arguments and results are sent by this code, with no encryption of its own, to whatever transport the caller supplies; the files add no credential, token or persistent storage. The doc comments state that a mutating tool's `reason` is recorded by the host in its activity entry, which is host behavior outside these files.

- **Data collected**: None by this code; the arguments and results it relays may contain user data.
- **Storage**: None; `ToolOutcome.inverse` is data only and these files do not persist it.
- **Transmission**: To the host over the caller's transport; the host's transport owns confidentiality and authentication.
- **Retention**: None in these files.

