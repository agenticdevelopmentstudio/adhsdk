
- **render-title-in-toolbar**: The EditorSection MUST render `title` (and the
  optional `titleBadge` accessory) as the leading content of the `ButtonBar`, in
  the gold mono title treatment.
- **derive-editing-from-selection**: The EditorSection MUST treat a non-null
  `selectedId` as "editing", and a null `selectedId` as "nothing selected".
- **show-detail-while-editing**: The EditorSection MUST render `children` in
  the detail pane while editing, and MUST render the `EmptyState` (titled
  `emptyDetail`) in the pane while nothing is selected.
- **gate-save-on-dirty-selection**: The EditorSection MUST enable Save only
  when editing AND `dirty` is true; otherwise Save MUST be disabled.
- **gate-cancel-on-editing**: The EditorSection MUST enable Cancel only while
  editing.
- **default-can-delete-to-editing**: The EditorSection MUST default the Delete
  enablement to "a record is selected" (`canDelete ?? editing`), and MUST honor an
  explicit `canDelete={false}` so Delete is not offered on an unsaved/new draft.
- **disable-delete-while-busy**: The EditorSection MUST disable Delete while
  `busy` is true.
- **disable-save-while-busy**: The EditorSection MUST disable Save while `busy`
  is true, regardless of `dirty`, and MUST render its label as "Saving…" for the
  duration.
- **disable-cancel-while-busy**: The EditorSection MUST disable Cancel while
  `busy` is true, regardless of editing.
- **keep-new-enabled-while-busy**: The EditorSection MUST NOT disable New while
  `busy` is true; New stays clickable so a second record can be started while
  the first is saving.
- **omit-delete-when-no-handler**: The EditorSection MUST hide the Delete
  button (`showDelete={false}`) when no `onDelete` handler is supplied.
- **render-warn-badge-per-row**: For a record with `warn` true, the
  EditorSection MUST render a trailing warning on its rail row — a `⚠ N` accent
  `Badge` when `warnCount` is set, otherwise a bare `⚠` — carrying `warnTitle` as
  its `aria-label` (and `title`); because that badge/span sits inside the rail
  row's own button, the `aria-label` composes into the row's accessible name
  alongside the visible label. A record with `warn` falsy MUST render no
  trailing warning.
- **surface-mutation-error**: When `error` is set, the EditorSection MUST
  surface it as a red line directly beneath the toolbar; when `error` is absent it
  MUST render no error line.
- **collapse-list-header-when-collapsed**: The EditorSection MUST place
  `listHeader` in the rail's leading slot and MUST hide it while the rail is
  collapsed.
- **default-empty-list-label**: The EditorSection MUST render `emptyList` as the
  rail's empty-state label when `items` is empty, defaulting to the hardcoded
  English literal `"Nothing here yet."` when `emptyList` is omitted.

