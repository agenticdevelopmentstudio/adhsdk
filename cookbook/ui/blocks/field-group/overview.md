
The shared `FieldGroup` in `@adh-sdk/ui` — the standard sectioning wrapper for
settings and editor forms. It is a bordered card with an uppercase-mono title row
across the top and its `Field` children stacked below, so a settings pane reads as a
series of titled groups instead of a flat wall of inputs.

The title row also carries an optional `trailing` accessory pinned to its right
edge — a status line ("Saved"), a small action (a "Reset" button), or a badge —
that belongs to the group as a whole rather than to any one field.

`FieldGroup` is presentation-only: it owns no form state and imposes no field type.
It composes the shared `Field` ([adhsdk.ingredient.ui.blocks.field](cookbook:0c199036-81c3-47c3-9e79-e4b8187ca69a)) as its
expected children and reuses the same `fieldCaptionClass` caption treatment as the
field caption, so the group title and the field captions share one visual language.

