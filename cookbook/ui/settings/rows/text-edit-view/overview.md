
The Text Edit View is a settings row: a leading label paired with a trailing
plain text field, bound to a string-valued view model. It builds its text
field through an overridable construction point so a variant can substitute
a different control type while inheriting everything else — the row layout,
the theme-driven font/color styling, the edit-completion commit path, and
the view-model sync. The Secure Text Edit View (documented separately at
[adhsdk.ingredient.ui.settings.rows.secure-text-edit-view](cookbook:2e0bf51e-905d-476d-9c0c-48465174ba59)) is the
one variant that exists today: it overrides that construction point to
return a secure text-entry control, and the control-view, editable-fields,
stored-value-changed and reload hooks to add its revealed field and its copy
and reveal buttons. This ingredient documents the Text Edit View
itself: the behavior every row built from it — plain or secure — inherits.

