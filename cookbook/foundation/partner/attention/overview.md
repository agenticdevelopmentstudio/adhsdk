
The data shapes for the partner's attention list: something the partner needs the owner to look at (`AttentionItem`), what it asks (`AttentionKind`), where it is in its life (`AttentionState`), and one owner action on an item kept as history (`AttentionAction`, with `AttentionActionKind`). The file is Foundation only and holds values and their initializers; it has no storage, no transitions between states and no behavior beyond construction, `Codable`, `Equatable` and `Identifiable` conformance. Whatever moves an item between states, and whatever persists the items, lives outside this file.

