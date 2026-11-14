
The inline commit control lives trailing-aligned inside (or adjacent to) an
editable element — canonically the last cell of a DataTable row. While the
element's data is clean it stays out of the way (at most a hover-revealed
trash affordance); the moment the data goes dirty it shows a ✓ (commit) / ✕
(cancel) icon-button pair that persists until the edits are saved or
discarded. It also owns the inline delete grammar: the trash arms a *pending*
delete — the consumer dims and strikes the content — and the same ✓ then
commits the removal.

Five cooperating exports form the pattern, all from
`@adh-sdk/ui/components/inline-commit-control` (plus the sibling
`unsaved-changes-guard`):

- `InlineCommitControl` — the stateless control itself.
- `InlineEditableText` — click-to-edit text (the shared `Input` with its field
  shell suppressed until hover/focus) whose edits make the row dirty. A
  `variant` (`mono` / `muted`) applies the two typography treatments consumers
  were overriding by hand (keys/identifiers vs. secondary text).
- `inlineCommitDeletingClass` — the class the consumer applies to content
  while its delete is armed (dim + strikethrough).
- `UnsavedChangesGuard` — page-level guard: while anything is dirty,
  navigation raises a confirm dialog (in-app links via the platform
  AlertModal, hard navigation via `beforeunload`, Back/Forward via a
  history sentinel, and opted-in programmatic navigation via the
  navigation-guard registry).
- `useInlineDrafts` (`@adh-sdk/ui/hooks/useInlineDrafts`) — the
  optional per-row state machine consumers were copy-pasting: PATCH-based
  drafts (only touched fields, so a commit never clobbers a field a
  background refetch changed), per-row in-flight gating, per-row errors, and
  `settle` (keeps keystrokes typed while a commit was in flight).

The consumer owns the data — draft values, dirty computation, the armed
delete — mirroring ButtonBar's contract; the control just renders it. The
`useInlineDrafts` hook is the shared implementation of that state, not a
requirement (any data layer plugs in).

