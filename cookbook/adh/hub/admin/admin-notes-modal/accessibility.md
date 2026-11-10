
- Role and keyboard/focus-trap behavior for both dialogs (outer and note editor) come
  unmodified from the shared dialog ingredient; see [adhsdk.ingredient.ui.components.overlays.dialog](cookbook:972be0d0-a9f5-45cd-a23b-c8329410b3d1)
  rather than restating it here.
- The note list carries the accessible label "Admin notes" (supplied to the list-with-details
  pane); how that label is applied internally is the list-with-details pane's own concern —
  see [adhsdk.recipe.ui.blocks.list-with-details-pane](cookbook:6acd3c5f-7bb5-4d6d-8c8d-141e1909cf73).
- The note editor's text field carries an accessible label of "Note content".
- Cancel/Save (outer) and Cancel/Save/Edit (editor and detail pane) are all instances of the
  shared button ingredient, with visible text labels and native keyboard activation; see
  [adhsdk.ingredient.ui.components.actions.button](cookbook:f3c25236-d72f-4a7b-839a-b7f335b3acd0).
- Touch/click target sizing for every control in this component is the shared button
  ingredient's concern (all instances use its small size variant) and is not restated here.
- The source defines no live-region announcement and no visual indicator tied to `busy`
  beyond disabling the outer Save control; per the component's own documentation the caller
  owns the save mutation and decides when to close the dialog, so this component has no
  failure state of its own to announce (see Edge Cases > Error states, and Design Decisions).

