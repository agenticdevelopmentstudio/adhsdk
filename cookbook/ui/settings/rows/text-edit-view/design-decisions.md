
- **Decision**: Give the text field itself — not a control view a variant
  wraps it in — a horizontal content-hugging priority (AppKit:
  `NSLayoutConstraint.Priority(1)`) below the row spacer's, rather than
  leaving it at its default hugging.
  **Rationale**: per the source's own inline comment, this is "below the
  row spacer's hugging, so the field — not the gap — takes the width left
  over after the label. An empty field sized to its own content is a few
  points wide and unclickable." Without it, an empty text field would
  shrink to its own tiny intrinsic width and the spacer would absorb the
  row's slack instead. (AppKit source.)
  **Approved**: pending
- **Decision**: Declare the text-field construction point as an overridable
  factory (AppKit: `open class func makeTextField(initialValue:)`) instead
  of returning a fixed text field inline in the initializer.
  **Rationale**: this is the one seam the component designs in for
  variation — the secure variant overrides only this method to substitute
  a secure text-entry control, reusing every other line of the initializer
  (row layout, content-hugging, theme observation, commit wiring)
  unmodified.
  **Approved**: pending
- **Decision**: Attach theme-change styling inside the initializer rather
  than by returning an already-themed field type from the construction
  point.
  **Rationale**: per the source's own inline comment, "subclasses
  substitute their own field ... so the theme is attached here rather than
  by returning a `ThemedTextField` from the factory" — keeping theming in
  one place regardless of which control type the construction point
  returns. (AppKit source.)
  **Approved**: pending
- **Decision**: Style a placeholder when the `placeholder` option is set
  and on every later theme change, never on the construction-time apply.
  **Rationale**: the theme-observation mechanism (AppKit:
  `ThemePaletteObserver.init`) applies its closure immediately upon
  registration, which happens inside the initializer before any caller can
  set the `placeholder` option — so that first, construction-time apply
  always finds no placeholder set, and the restyling guard skips it.
  Setting the option therefore applies the theme to every editable field
  itself, at once, so the placeholder does not wait for a theme change to
  be styled.
  **Approved**: pending
- **Decision**: Perform no contrast check in the component, and accept that
  placeholder text is guaranteed only a 1.6:1 contrast floor against the
  background; the label and typed text (primary-text role) and the
  placeholder (placeholder-text role) take whatever the active theme
  resolves.
  **Rationale**: the theme layer's derivation for the placeholder-text role
  dims the theme's foreground toward its background with `minContrast:
  1.6` — below WCAG 2.1 SC 1.4.3's 4.5:1 floor for normal text. This is a
  theme-layer choice inherited by every themed field, including this one;
  the component neither sets nor can override it. Whether a given theme's
  resolved pairs reach 4.5:1 is not established by this component: closing
  the gap would take a theme-level audit (or an enforced minimum in the
  theme layer) of those roles against the backgrounds a settings row sits
  on, which no source or test does today. Recorded here as technical debt
  affecting accessibility correctness, per source-fidelity's requirement to
  document such debt rather than idealize it away.
  **Approved**: pending
- **Decision**: Link every editable field's accessible title to the label
  (AppKit: `setAccessibilityTitleUIElement(label)`), in the same loop that
  wires each field's commit path, the way the sibling checkbox row links
  its switch's accessibility title.
  **Rationale**: a bare text field has no name of its own, so without the
  link a screen reader announces it as an unnamed text field rather than by
  the row's title. Making the link per editable field, rather than on the
  text field alone, titles a variant's added fields (the secure row's
  revealed field) without the variant repeating it.
  **Approved**: pending
- **Decision**: Unconditionally overwrite the view model's change
  notification with the component's own handler during initialization,
  rather than chaining it after any previously registered handler.
  **Rationale**: the view model's change notification is a single callback
  property with no built-in multicast support; chaining would require a
  broader change to the shared view-model type, which is out of scope for
  this row component. The source accepts the tradeoff that one row (or
  other observer, including the secure variant) per view model instance is
  the supported usage (see **claims-sole-onchange-observer**).
  **Approved**: pending

