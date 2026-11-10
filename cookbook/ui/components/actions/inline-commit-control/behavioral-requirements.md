
- **hide-when-clean**: The control MUST render nothing while the data is
  clean, except the delete affordance when the data is deletable.
- **reveal-trash-on-hover**: When clean and deletable, the control MUST
  reveal a trash icon button on hover of its enclosing hover scope
  (`inlineCommitHoverScopeClass`; DataTable rows provide it) and on keyboard
  focus.
- **show-pair-when-dirty**: The control MUST show the ✓/✕ pair whenever
  the data is dirty, and keep showing it until the edits are committed or
  cancelled.
- **commit-on-ok**: Clicking ✓ MUST invoke the consumer's commit action
  (save to the backing store); the consumer hides the control by clearing the
  dirty state on success.
- **cancel-on-x**: Clicking ✕ MUST invoke the consumer's cancel action,
  reverting the draft to the committed data.
- **arm-delete**: Clicking the idle trash MUST arm a pending delete
  rather than deleting immediately.
- **render-armed-delete**: While a delete is armed the control MUST show
  ✓ ✕ followed by a red trash as the right-most button, and the consumer MUST
  dim and strike the affected content (`inlineCommitDeletingClass`).
- **commit-armed-delete**: Clicking ✓ while a delete is armed MUST invoke
  the consumer's commit action, which performs the delete.
- **disarm-delete**: Clicking ✕ (or the armed red trash) while a delete
  is armed MUST disarm it, restoring the content's normal rendering without
  deleting.
- **disable-while-busy**: While a commit is in flight the control MUST
  neutralize its buttons (ignore clicks) and indicate progress in place of the
  ✓. It MUST use `aria-disabled` rather than the `disabled` attribute, so the
  button keeps keyboard focus across the in-flight transition.
- **edit-in-place**: Editable text using `InlineEditableText` MUST become
  editable with a single click in place, and edits MUST make the row dirty.
- **guard-navigation-when-dirty**: While any attached data is dirty, the
  page MUST prevent navigation without a confirmation dialog
  (`UnsavedChangesGuard`): in-app link clicks raise the platform AlertModal
  confirm; reload/close raises the browser's native leave prompt; Back/Forward
  raises the AlertModal (via a same-URL history sentinel); and chrome that
  navigates programmatically (menus, choosers, logout) raises it too when it
  awaits `confirmNavigation()` from the navigation-guard registry.
- **route-keyboard**: `InlineEditableText` SHOULD route Enter to the
  row's commit action and Escape to its cancel action; a consumer-supplied
  `onKeyDown` runs FIRST and may `preventDefault()` to suppress that routing.
- **preserve-focus**: The control SHOULD keep keyboard focus coherent
  across state changes — arming a delete focuses the ✓ (confirming is one
  keypress); committing/cancelling re-anchors focus on the idle trash.

