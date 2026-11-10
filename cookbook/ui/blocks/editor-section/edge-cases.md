
- Nothing selected (`selectedId === null`): the pane shows `EmptyState`, Cancel and
  Save are disabled, and Delete defaults to disabled (nothing to delete).
- New/unsaved draft: the consumer passes `canDelete={false}` so Delete is not
  offered for a row that isn't persisted yet, even though a draft is being edited.
- Empty record list: the rail shows `emptyList` (falling back to the hardcoded
  English literal "Nothing here yet." when omitted — see
  **default-empty-list-label**; this default is not localized).
- `busy` (saving) in flight: Save renders "Saving…" and is disabled, Cancel is
  disabled, and Delete is disabled, so a record can't be canceled out of or
  deleted mid-save; New remains enabled so a second record can be started (see
  **disable-save-while-busy**, **disable-cancel-while-busy**,
  **disable-delete-while-busy**, **keep-new-enabled-while-busy**).
- A row without `warn` renders no trailing accessory; a row with `warn` but no
  `warnCount` renders a bare `⚠` rather than a count badge.
- Rows whose labels are long identifiers (URLs): widen the rail via `railWidth`.
- The rail is always collapsible (a core `TopicDetail` behavior); collapsing hides
  the `listHeader` (see **collapse-list-header-when-collapsed**) and each row's
  warn badge/label, leaving the icon strip — that collapse-time hiding is
  `TopicDetail`'s own behavior (`support-trailing-accessory`,
  `hide-label-when-collapsed`; see
  behavioral-requirements ([adhsdk.ingredient.ui.blocks.topic-detail](cookbook:8fa7aaae-df62-44ea-b10c-182f3094ed9f))), not
  something EditorSection adds.

