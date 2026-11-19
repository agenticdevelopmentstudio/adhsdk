
All edge-case behavior — the non-optional view-model parameter ruling out
a missing value, unbounded text length, UI-thread-serialized concurrent
access, the absence of any throwing or error-producing API, no
networking, and the change-notification-callback overwrite when a second
observer is constructed against the same view model — is inherited
unmodified from the text edit row, whose initializer this component
reuses without change; see
edge-cases ([adhsdk.ingredient.ui.settings.rows.text-edit-view](cookbook:c1787e74-2485-4d7b-a219-feb4c07cf97c)).
This component's own edge cases:

- Reveal while editing: switching between obscured and shown keeps the
  typed, uncommitted text and keeps the field first responder.
- Copy while editing: copies the field's current text, which may not be
  committed yet.
- An empty value: copy is disabled; the eye still toggles, so a person can
  see what they type.
- The window resigns key because the person opened a sheet or popover from
  the same window: the secret is obscured anyway; it is the person's to show
  again.
- Two rows bound to the same setting: each has its own shown state; an
  external change made by the other row obscures this one.

