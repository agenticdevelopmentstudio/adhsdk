
- **Null / empty input**: An empty `model` and an empty `allowedTools` each drop their option (MUST). An empty `permissionMode`, `mcpConfigPath`, `systemPromptPath` or `executable` is passed through as an empty element or path; nothing rejects it (MUST NOT validate).
- **Boundary values**: `allowedTools` of one entry gives one element after `--allowedTools`; every entry is a separate argument, so an entry containing spaces stays one element.
- **Odd tool entries**: An `allowedTools` entry that is empty, or starts with `-` or `--`, is passed through unchanged as its own element, like every other value (MUST NOT validate); the type does not guard against the CLI reading it as a flag.
- **Concurrent access**: The type is a `Sendable` value; a copy can be read from any thread or actor.
- **Error states**: `arguments` cannot fail; a configuration naming a missing executable or file is only discovered when the process is launched, which is `PartnerProcess`'s concern.
- **Offline / disconnected state**: Not applicable: the type performs no network or file access.
- **Cancellation**: Not applicable: `arguments` is a synchronous computation.

