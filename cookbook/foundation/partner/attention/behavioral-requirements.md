
**Enumerations**

- **kind-values**: `AttentionKind` MUST be a String-backed enum with exactly the raw values `question`, `blocked` and `notification`, and MUST be `Codable`, `Sendable` and `CaseIterable`; `AttentionKind.allCases` MUST list the three kinds in declaration order. `AttentionState` and `AttentionActionKind` need not be `CaseIterable`.
- **state-values**: `AttentionState` MUST be a String-backed enum with exactly the raw values `open`, `discussing`, `sent` and `done`, and MUST be `Codable` and `Sendable`.
- **action-kind-values**: `AttentionActionKind` MUST be a String-backed enum with exactly the raw values `discuss`, `resolved`, `confirm` and `reopen`, and MUST be `Codable` and `Sendable`.

**Attention item**

- **item-fields**: `AttentionItem` MUST carry `id` (String), `kind` (`AttentionKind`), `text` (String), `reference` (a String-to-String dictionary), `state` (`AttentionState`), `createdBy` (String), `createdAt` (Date), `updatedAt` (Date) and `completedAt` (optional Date).
- **item-conformances**: `AttentionItem` MUST be `Codable`, `Sendable`, `Equatable` and `Identifiable`, with `id` as the identity.
- **item-mutable**: Every `AttentionItem` field MUST be a mutable stored property, so a holder updates an item in place.
- **item-init-required**: The `AttentionItem` initializer MUST require `kind`, `text` and `createdBy`.
- **item-init-id-default**: The `AttentionItem` initializer MUST default `id` to a fresh `UUID().uuidString`.
- **item-init-explicit**: Every `AttentionItem` initializer parameter MUST be stored exactly as passed.
- **item-init-defaults**: The `AttentionItem` initializer MUST default `reference` to an empty dictionary, `state` to `.open` and `completedAt` to `nil`.
- **item-init-dates**: The `AttentionItem` initializer MUST default both `createdAt` and `updatedAt` to the current date at the time of the call; when both default, `createdAt` and `updatedAt` MAY differ slightly.
- **item-completed-optional**: `completedAt` MUST be `nil` until a holder sets it, and an `AttentionItem` MUST NOT set it or tie it to the `done` state on its own.

**Attention action**

- **action-fields**: `AttentionAction` MUST carry `id` (String), `itemID` (String), `action` (`AttentionActionKind`), `at` (Date) and `messageID` (optional String).
- **action-conformances**: `AttentionAction` MUST be `Codable`, `Sendable`, `Equatable` and `Identifiable`, with `id` as the identity.
- **action-init-required**: The `AttentionAction` initializer MUST require `itemID` and `action`.
- **action-init-defaults**: The `AttentionAction` initializer MUST default `id` to a fresh `UUID().uuidString`, `at` to the current date and `messageID` to `nil`.
- **action-references-item-by-id**: `AttentionAction.itemID` MUST name its item by the item's `id`, and an `AttentionAction` MUST NOT check that such an item exists.

**Wire form**

- **wire-keys**: Encoding MUST use the Swift property names as JSON keys (`id`, `kind`, `text`, `reference`, `state`, `createdBy`, `createdAt`, `updatedAt`, `completedAt`; `id`, `itemID`, `action`, `at`, `messageID`), because neither type declares custom coding keys.
- **wire-enum-strings**: Each enum MUST encode as its raw String value.
- **wire-required-on-decode**: Decoding MUST fail when a non-optional field is missing, because the initializer defaults do not apply to decoding.
- **wire-optional-on-decode**: Decoding MUST accept a missing `completedAt` or `messageID` as `nil`.
- **wire-unknown-enum-fails**: Decoding MUST fail for a `kind`, `state` or `action` value outside its enum's raw values; there is no fallback case.
- **wire-dates-strategy**: An encoder and a decoder of these types MUST share one date strategy; the types set no `dateEncodingStrategy` or `dateDecodingStrategy` of their own, so each store chooses one.

