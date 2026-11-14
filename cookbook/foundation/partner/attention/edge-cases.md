
- **Empty and null input**: An empty `text`, an empty `createdBy` and an empty `reference` are all accepted; the file validates nothing.
- **Duplicate ids**: Two items or two actions with the same `id` are accepted; `Identifiable` identity is then ambiguous. The caller owns uniqueness; the default `UUID().uuidString` makes a collision negligible.
- **Dangling action**: An `AttentionAction` whose `itemID` matches no item is accepted; the types do not link the two.
- **Completion date**: The types never set `completedAt` and do not tie it to the `done` state; a holder sets it.
- **Default dates**: When an item is built with no dates, `createdAt` and `updatedAt` come from two separate clock reads and may differ slightly.
- **Inconsistent timestamps**: `updatedAt` earlier than `createdAt`, or a `completedAt` on an item that is not `done`, is accepted and not corrected.
- **State changes do not touch dates**: Changing `state` does not update `updatedAt` or `completedAt`; a holder sets them.
- **Unknown enum value on the wire**: A newer writer's new `kind`, `state` or `action` raw value makes decoding of that whole item or action fail on an older reader.
- **Date strategy mismatch**: Encoding and decoding with different date strategies fails or corrupts dates; this file does not choose one.
- **Concurrent access**: All types are `Sendable` value types with no shared mutable state, so copies are safe on any thread; serialisation of updates to a shared collection is the holder's.
- **Error states and offline state**: Not applicable: the types perform no I/O and raise no errors beyond `Codable` decoding failures.

