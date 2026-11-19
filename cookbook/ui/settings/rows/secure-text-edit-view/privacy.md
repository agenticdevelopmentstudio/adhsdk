
- **Data collected**: The field's typed value — per the source's own doc
  comment, typically a secret such as an API key or password. On screen the
  component masks it as dots, and shows it in plain text only after the
  person presses the eye, and only until the window resigns key, the app
  resigns active, the view leaves its window or the setting changes from
  outside; the shown state is never persisted. Beyond that on-screen
  masking the component does not classify or redact the value; it holds it in the
  view model's value and passes it through unchanged (see
  privacy ([adhsdk.ingredient.ui.settings.rows.text-edit-view](cookbook:c1787e74-2485-4d7b-a219-feb4c07cf97c)) for
  the storage, transmission, and retention behavior this shares with the
  text edit row, which applies to whatever string value either component
  holds).
- **Storage**: Not applicable within this component's own source itself —
  persistence, when it happens, is owned by the caller-supplied view
  model's backing setting: the settings store routes a setting with
  secure storage enabled to a secure storage provider (a keychain-backed
  one, by default) — this is the reason the source recommends this view
  for secrets, but none of it is code in this component's own source
  itself.
- **Transmission**: No networking. The copy button writes the secret to
  the general pasteboard as plain text only, with no concealed or transient
  marking and no expiry, so any app, clipboard managers and Universal
  Clipboard can read and keep it (see Design Decisions); that is the
  person's explicit act and the component writes it nowhere else.
- **Retention**: Inherited unmodified from the text edit row — the value
  lives only in the field and the view model's value for as long as the
  row is on screen and its view model is retained; see
  privacy ([adhsdk.ingredient.ui.settings.rows.text-edit-view](cookbook:c1787e74-2485-4d7b-a219-feb4c07cf97c)).
- **Security-violation handling**: Not applicable — this component has no
  detection surface of its own (no validation, rate-limiting, or
  authentication logic); it only masks, reveals and copies. Any
  violation-handling behavior belongs to whatever storage/auth layer the
  caller's setting is wired to, outside these two files.

