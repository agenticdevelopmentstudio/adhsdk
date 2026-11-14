
- **value-semantics**: `PartnerProcessConfiguration` MUST be a `Sendable` and `Equatable` struct with the settable fields `executable`, `sessionID` (a UUID), `resume`, `model`, `permissionMode`, `allowedTools` (strings), `mcpConfigPath`, `systemPromptPath` and `workingDirectory`, all set by its initializer.
- **fixed-prefix**: `arguments` MUST begin with `-p`, `--verbose`, `--input-format`, `stream-json`, `--output-format`, `stream-json`, `--replay-user-messages`, in that order.
- **session-flag**: After the fixed prefix, `arguments` MUST contain `--session-id` when `resume` is false and `--resume` when `resume` is true, never both and never neither, followed by the session ID.
- **session-id-lowercase**: The session ID in `arguments` MUST be the UUID string in lowercase.
- **permission-mode**: `arguments` MUST contain `--permission-mode` followed by `permissionMode` unchanged and unconditionally, including when it is empty.
- **mcp-config**: `arguments` MUST contain `--mcp-config` followed by `mcpConfigPath`, then `--strict-mcp-config`.
- **system-prompt**: `arguments` MUST contain `--append-system-prompt-file` followed by `systemPromptPath`.
- **optional-model**: `arguments` MUST add `--model` followed by `model` only when `model` is not empty; an empty `model` MUST add neither element.
- **optional-tools**: `arguments` MUST add `--allowedTools` followed by each entry of `allowedTools` as its own element only when `allowedTools` is not empty; an empty list MUST add neither.
- **order**: The required groups MUST appear in this order after the session flag and ID: `--permission-mode` and its value, `--mcp-config` and its value, `--strict-mcp-config`, then `--append-system-prompt-file` and its value. The optional arguments MUST come after the required ones, the model option before the tools option.
- **pure-computation**: `arguments` MUST be computed from the stored fields alone; it MUST NOT touch the file system, check that the executable or paths exist, or validate any value.
- **working-directory-not-an-argument**: `workingDirectory` MUST NOT appear in `arguments`; it is the child's current directory, which `PartnerProcess` applies when it launches.

