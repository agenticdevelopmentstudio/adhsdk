
- **Decision**: `EditorSection` is a pure assembly with no visual grammar of its
  own.
  **Rationale**: Every editor topic must look identical; delegating all
  appearance to `ButtonBar` + `TopicDetail` + `EmptyState` keeps one blessed home
  for each part and avoids drift (optimize-for-change).
  **Approved**: pending
- **Decision**: The consumer owns all state (list, selection, draft, dirty, busy,
  error) and callbacks.
  **Rationale**: The shell computes only derived enablement;
  keeping the source of truth outside makes it reusable across every record type.
  **Approved**: pending
- **Decision**: "Editing" is derived from `selectedId !== null`, and Save from
  `editing && dirty`.
  **Rationale**: One selection prop drives both the pane
  choice and the toolbar enablement, so callers can't put the two out of sync.
  **Approved**: pending
- **Decision**: `canDelete` defaults to "anything selected" but honors an explicit
  `false`.
  **Rationale**: The common case needs no wiring, while a new/unsaved
  draft can suppress a Delete that would target a non-row.
  **Approved**: pending
- **Decision**: Warn rendering is data-driven from `warn`/`warnCount`/`warnTitle`
  on each item, mapping to a `Badge` or a bare `⚠`.
  **Rationale**: The rail stays a
  generic `TopicDetail`; the "needs configuration" affordance is expressed as data,
  not a new rail feature.
  **Approved**: pending

