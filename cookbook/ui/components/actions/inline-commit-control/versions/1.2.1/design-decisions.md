
- **Decision**: The control renders `dirty`/`deleting`/`busy` and reports
  intent via callbacks; it never holds draft data itself (ButtonBar
  precedent).
  **Rationale**: Any data layer (react-query, local state) plugs in. The
  optional `useInlineDrafts` hook is the shared implementation of that state.
  **Approved**: pending
- **Decision**: `useInlineDrafts` stores a draft as only the fields the user
  touched, and `settle` drops only the committed keys.
  **Rationale**: A commit then sends — and can clobber — nothing else, even
  after a background refetch changes a sibling field, and keystrokes typed
  mid-flight survive.
  **Approved**: pending
- **Decision**: Busy buttons use `aria-disabled` rather than `disabled`.
  **Rationale**: The buttons stay in the tab order and keep focus across the
  in-flight transition (a `disabled` button loses focus to `<body>`), so
  keyboard commit → busy → done is seamless.
  **Approved**: pending
- **Decision**: Programmatic navigators opt in to the guard through a
  registry callback (`await confirmNavigation()`) instead of an anchor-click
  interceptor.
  **Rationale**: A click interceptor can't see a `router.push`; a tiny
  registry lets every menu/logout share one confirm instead of
  reimplementing it.
  **Approved**: pending
- **Decision**: A delete is staged (armed) and confirmed by the same ✓
  grammar as edits, rather than deleted instantly.
  **Rationale**: One commit vocabulary covers the whole row instead of a
  separate modal per delete.
  **Approved**: pending
- **Decision**: Clicking the armed red trash disarms it.
  **Rationale**: A small reversible action doesn't need a second
  confirmation.
  **Approved**: pending
- **Decision**: `InlineEditableText` is a transparent `Input`, not a
  text-node/edit-mode swap.
  **Rationale**: One fewer state machine — the field is always the real
  input (simplicity, native-controls).
  **Approved**: pending
- **Decision**: The navigation guard raises the platform `AlertModal` for
  in-app links instead of the native `confirm()`; native `beforeunload`
  remains for hard unloads.
  **Rationale**: Consistent with the platform's dialog policy; `beforeunload`
  is kept because custom UI can't intercept a hard unload.
  **Approved**: pending

