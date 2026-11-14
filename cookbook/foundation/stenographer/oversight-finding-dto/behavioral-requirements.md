
**Shape**

- **value-conformances**: `OversightFindingDTO` MUST be an immutable value type that is `Codable`, `Sendable` and `Equatable`.
- **field-set**: `OversightFindingDTO` MUST carry exactly these fields: `id` (Int), `sessionId`, `observer`, `kind` (String), `severity` (Int), `status`, `source`, `model`, `reason`, `detail` (String), `createdAt` and `updatedAt` (String).
- **fields-immutable**: Every field MUST be read-only after construction; the type MUST NOT expose a mutating member.
- **init-all-fields**: The public initializer MUST take all twelve fields in the order `id`, `sessionId`, `observer`, `kind`, `severity`, `status`, `source`, `model`, `reason`, `detail`, `createdAt`, `updatedAt`, and MUST NOT give any of them a default value.
- **no-identifiable**: The type MUST NOT declare `Identifiable`; a consumer that needs row identity keys on `id` itself.

**Field meaning**

- **session-id**: The producer (the daemon) MUST set `sessionId` to the session the finding is about. The DTO does not enforce this.
- **observer-namespace**: `observer` MUST name the observer that produced the finding (example in the source: `"context"`) and namespaces the finding. For a script-driven finding the daemon uses the script's `id` as the observer, as the OversightScript doc comment states.
- **kind-dispatch**: `kind` MUST be the actionable category an actor can dispatch on (example in the source: `"compact"`).
- **severity-hint**: `severity` MUST be an Int described as a coarse 0 to 100 urgency and an ordering hint; the type MUST NOT clamp or reject a value outside that range.
- **status-lifecycle**: `status` MUST be a free String documented to take one of `pending`, `acted`, `dismissed` or `stale`; the type MUST NOT be an enum and MUST NOT reject another spelling.
- **source-values**: `source` MUST be a free String documented to take `rule` or `llm`; the type MUST NOT reject another spelling.
- **model-empty-for-rule**: The producer (the daemon) MUST set `model` to the model behind an `llm`-sourced finding and to the empty string for a `rule` finding. The DTO does not enforce this; it carries whatever string it is given.
- **reason-line**: The producer (the daemon) MUST set `reason` to one human-readable line explaining the finding. The DTO does not enforce this.
- **detail-opaque**: `detail` MUST be an opaque string documented as an optional JSON blob of extra structured context, empty when there is none; the type MUST NOT parse it.
- **timestamps-opaque**: `createdAt` and `updatedAt` MUST be carried as the strings the daemon stored; the type MUST NOT parse, reformat or compare them.

**Wire**

- **wire-spelling**: The finding MUST travel in the stenographer-wide wire spelling (snake_case keys through the shared `StenographerWire` encoder and decoder), so the fields appear as `id`, `session_id`, `observer`, `kind`, `severity`, `status`, `source`, `model`, `reason`, `detail`, `created_at` and `updated_at`.
- **decode-strict**: Decoding MUST fail when any of the twelve keys is missing; the type has no hand-written decoder and no key is optional.
- **decode-lenient-values**: Decoding MUST accept any String for `status` and `source`, and MUST accept the empty string for every string field.
- **equality-all-fields**: Two findings MUST compare equal exactly when all twelve fields are equal.
- **read-only-for-clients**: A client MUST treat a finding as read-only; the daemon is the only writer, and a client changes a finding's state only by calling the daemon's act operation.

**Delivery**

- **ordering-owner**: The type MUST NOT impose an order. Ordering and row caps belong to the daemon routes spec.

