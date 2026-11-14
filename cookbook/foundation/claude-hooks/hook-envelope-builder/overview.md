
`HookEnvelopeBuilder` is the daemon-side counterpart of the hook capture command. A daemon that listens for hooks receives them in one of two forms: over its Unix socket, as the wire format a hook script sends (event, `ppid`, `KEY=value` environment lines, a `---` line, then the payload), or over an `http` hook, which carries only the payload JSON. The builder turns either into a `ParsedEvent` ready for ingestion, with the same context shape the capture command writes into a drop file, so events that arrive over the socket and through drop files are queryable identically.

The file holds three things. `HookEnvelopeBuilder` has two `build` overloads (the payload-only http form and the full socket form), `buildContext`, `parseWire` and the stored `daemonWorkingDirectory`. `HookEnvCache` is a lock-guarded memo, with a three-second time to live, for the two expensive lookups the http form needs: which `claude` process owns a working directory, and what that process's environment is. The account lookups are injected closures because the toolkit core has no account store; both default to the empty string, the "no answer" value.

The system fields (`hostname`, `os`, `arch`, `uid`, `euid`, `gid`) are computed in the calling process. The source states that a daemon runs as the same user as the hook-firing process, so they match.

