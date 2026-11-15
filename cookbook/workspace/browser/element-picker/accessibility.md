
- The address-bar button has the accessibility identifier
  `browser.hide-items`, and its accessibility label follows its tooltip
  ("Hide distracting items", or "Stop selecting" while selecting).
- The popover's controls are native controls with their visible titles as
  labels; each row's checkbox is labelled with the entry's label.
- Esc ends selecting mode without a pointer, and the dialog is fully
  usable from the keyboard (Return for OK, Esc for Cancel).
- Selecting an element itself needs a pointer; there is no keyboard
  traversal of page elements (a builder's choice, see Design Decisions).

