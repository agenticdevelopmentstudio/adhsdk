
- **field-set**: The DTO MUST carry exactly these fields: `id` (`Int`), `feature`, `sessionId`, `providerKind`, `configName`, `model`, `systemPrompt`, `userPrompt`, `response` (all `String`), `durationMs` (`Int`), `outcome`, `error` (`String`), `truncated` (`Bool`) and `createdAt` (`String`).
- **immutable**: Every field MUST be a constant set once by the initializer.
- **codable-keys**: The DTO MUST encode and decode with its property names as the wire keys, using the synthesized `Codable` conformance.
- **decode-all-required**: Decoding MUST fail when any of the fourteen keys is missing; unlike its sibling `ConversationEntryDTO`, it has no tolerant decode.
- **initializer-complete**: The public memberwise initializer MUST take every field and MUST NOT give any field a default.
- **feature-vocabulary**: `feature` is documented as `summarize` or `oversight`, naming which feature asked; the type MUST NOT reject any other string.
- **provider-kind-vocabulary**: `providerKind` is documented as `plugin` (a selected provider configuration) or `cli` (the zero-config `claude -p` fallback); the type MUST NOT reject any other string.
- **outcome-vocabulary**: `outcome` is documented as `ok`, `error`, `guard_blocked` or `guard_deferred`; the type MUST NOT reject any other string.
- **is-failure**: `isFailure` MUST be true for every `outcome` other than the exact string `ok`, including a value outside the documented four.
- **is-failure-case-sensitive**: `isFailure` MUST compare `outcome` exactly, so `OK` counts as a failure.
- **truncated-list**: `truncated` MUST report whether the producer cut any of `systemPrompt`, `userPrompt` or `response`, so a viewer knows to fetch the full text by id. (The daemon store's list read is the producer that cuts and sets it.)
- **truncated-detail**: A producer that returns the full text (the daemon store's by-id read) MUST set `truncated` to false.
- **timestamp-text**: `createdAt` MUST be carried as the text the daemon stored, with no parsing or reformatting by the DTO.
- **verbatim-no-redaction**: The DTO MUST carry prompts and responses verbatim; it applies no redaction.
- **decoder-empty-string-present**: A decoder MUST NOT treat an empty string as a missing value.

### Producer contract

The type cannot enforce these; whoever builds the DTO (`AIInteractionStore`, `DaemonAIChat`) MUST honor them.

- **session-id-empty**: `sessionId` MUST be the empty string when the call was not scoped to a session.
- **config-name-empty-on-cli**: `configName` MUST be the empty string on the CLI path.
- **model-label**: `model` MUST be the model label the call resolved to: the configuration's model, the plugin id, or the CLI model.
- **failure-reason**: When the call did not complete, `error` MUST hold the reason and `response` MUST be empty; on success `error` MUST be the empty string.

### Consumer contract

The type cannot enforce this; the AI Log window is the consumer.

- **rendering-split**: List and detail rendering MUST derive their success/failure split from `isFailure` and not from comparing `outcome` themselves.
