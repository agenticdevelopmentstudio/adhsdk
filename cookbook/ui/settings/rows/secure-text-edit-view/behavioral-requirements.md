
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
- **eye-icon-tracks-state**: The eye button MUST show a reveal (open-eye)
  glyph while obscured and a conceal (struck-through eye) glyph while shown.
- **reobscure-on-window-resign-key**: A shown secret MUST return to obscured
  when the view's window resigns key.
- **reobscure-on-app-resign-active**: A shown secret MUST return to obscured
  when the app resigns active.
- **reobscure-on-leave-window**: A shown secret MUST return to obscured when
  the view is removed from its window, so a row that comes back is obscured.
- **reobscure-on-external-change**: A shown secret MUST return to obscured
  when the field's setting changes from outside the row (the view-model sync
  path), and the new value MUST show as dots.
- **own-commit-keeps-shown**: The row's own commit MUST NOT re-obscure a shown
  secret: a stored value equal to the text the row is showing is not an
  external change, so the row stays shown.
- **reveal-state-not-persisted**: The shown state MUST be held only in the
  view and MUST NOT be written to any setting or store; every new row starts
  obscured.
- **edits-commit-in-either-state**: An edit made while shown MUST commit
  through the same commit path, with the same redundant-commit guard, as an
  edit made while obscured.
- **titles-fields-with-label**: Every field the row edits — the masked
  field and the plain field shown while revealed — MUST take its accessible
  title from the row's label, so a screen reader names either field by the
  row's title.
- **labels-accessory-buttons**: The copy button's accessibility label MUST be
  "Copy", and the eye button's MUST be "Show" while obscured and "Hide" while
  shown.
- **accessory-buttons-follow-field-in-key-order**: The key-view order MUST go
  from the field (obscured or shown) to the copy button, then to the eye
  button.

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

