
Decisions governing the text edit row's inherited behavior — the
content-hugging priority, the factory-method pattern, theme-observation
placement, placeholder-restyle timing, and the placeholder contrast floor
— are recorded at
design-decisions ([adhsdk.ingredient.ui.settings.rows.text-edit-view](cookbook:c1787e74-2485-4d7b-a219-feb4c07cf97c))
and are not repeated here.

- **Decision**: Implement this component as a specialization of the text
  edit row that overrides its field construction and adds the accessory
  buttons, rather than composing a new view from scratch.
  **Rationale**: This reuses all of the text edit row's row layout, theme
  styling, and commit wiring; a secure row differs only in its field and
  its two buttons.
  **Approved**: pending
- **Decision**: Re-obscure a shown secret on window resign key, app resign
  active, leaving the window and an external change, and never persist the
  shown state.
  **Rationale**: Each of those is a moment the person may stop watching the
  screen or the value is no longer the one they chose to see; a secret left
  in plain text in a background window is visible to anyone at the screen or
  in a screen share. A new row always starts obscured.
  **Approved**: pending
- **Decision**: Foreclose further specialization of this component
  (AppKit/UIKit source: declared `final`).
  **Rationale**: Traceable to `public final class SecureTextEditView:
  TextEditView` in source — forecloses further subclassing since it is the
  one masking variant the text edit row needs (see Platform Notes).
  **Approved**: pending
- **Decision**: Suppress a lint rule (AppKit/UIKit source: `//
  swiftlint:disable:next static_over_final_class`) on the
  field-construction override.
  **Rationale**: Overriding the text edit row's open factory method
  requires a non-static override even though this component itself
  forecloses further specialization, which trips a lint rule that
  otherwise prefers a static method — this is an intentional, documented
  suppression traceable to the source comment, not an accidental disable,
  and is recorded here per the source-fidelity requirement to document
  known workarounds.
  **Approved**: pending
- **Decision**: Treat storage and persistence of the masked value as
  entirely out of scope of this component's own source.
  **Rationale**: Per the source's own doc comment, the value is
  "typically" routed to a setting with secure storage enabled, which the
  settings store then routes to a keychain-backed secure storage provider;
  this component's own source only masks the on-screen glyphs and never
  itself reads or writes the keychain.
  **Approved**: pending

