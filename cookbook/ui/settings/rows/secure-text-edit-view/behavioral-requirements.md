
- **masks-entry-with-secure-field**: Component MUST construct its field as
  a masking (dot-obscured) secure text field, so the field is a secure,
  masking field rather than the plain field its base row would otherwise
  construct.
- **stored-secret-shows-as-dots**: A stored, non-empty secret MUST show as one
  dot glyph per character while the field is obscured, without the person
  having to focus or edit the field.
- **trailing-accessory-buttons**: The row MUST place two buttons after the
  field, right-aligned in the row: copy, then the eye.
- **copy-puts-secret-on-pasteboard**: The copy button MUST replace the
  general pasteboard's contents with the field's current value, as plain
  text, whether the secret is obscured or shown.
- **copy-disabled-when-empty**: The copy button MUST be disabled while the
  field's value is empty.
- **eye-toggles-reveal**: The eye button MUST toggle the field between
  obscured (dots) and shown (plain text), keeping the value, first
  responder and the commit path unchanged.
- **eye-icon-tracks-state**: The eye button MUST show the `eye` symbol while
  obscured and `eye.slash` while shown.
- **reobscure-on-window-resign-key**: A shown secret MUST return to obscured
  when the view's window resigns key.
- **reobscure-on-app-resign-active**: A shown secret MUST return to obscured
  when the app resigns active.
- **reobscure-on-leave-window**: A shown secret MUST return to obscured when
  the view is removed from its window, so a row that comes back is obscured.
- **reobscure-on-external-change**: A shown secret MUST return to obscured
  when the field's setting changes from outside the row (the view-model sync
  path), and the new value MUST show as dots.
- **reveal-state-not-persisted**: The shown state MUST be held only in the
  view and MUST NOT be written to any setting or store; every new row starts
  obscured.
- **edits-commit-in-either-state**: An edit made while shown MUST commit
  through the same commit path, with the same redundant-commit guard, as an
  edit made while obscured.

All other behavior — row layout, expanding the field to fill the row,
wiring the field's action, initializing from and syncing with the view
model, theme styling, restyling an existing placeholder, exposing the
label and the field, the designated-initializer-only construction rule,
and UI-thread confinement — is inherited unmodified from the text edit
row; see
behavioral-requirements ([adhsdk.ingredient.ui.settings.rows.text-edit-view](cookbook:c1787e74-2485-4d7b-a219-feb4c07cf97c))
(arranges-row-layout, expands-text-field-to-fill-row,
wires-text-field-action, initializes-from-view-model,
commits-value-on-change, skips-redundant-commits, syncs-on-external-change,
applies-theme-styling, restyles-existing-placeholder,
exposes-constituent-views, requires-designated-initializer,
rejects-frame-only-initialization, confines-to-ui-thread). Foreclosing
further specialization of this component is a platform-specific
construction detail, recorded in Platform Notes rather than as a
normative requirement here (see Platform Notes).

- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

