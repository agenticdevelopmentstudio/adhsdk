
- **adopt-to-own-the-gap**: Pane content that insets itself MUST adopt the
  protocol, so that the pane hands it the gap and pins it flush.
- **apply-pane-spacing-method**: A conforming type MUST implement
  `applyPaneSpacing(_ spacing: Spacing)`, the only requirement of the protocol.
- **main-actor-isolated**: The protocol MUST be isolated to the main actor, so
  `applyPaneSpacing(_:)` MUST be called on the main thread.
- **class-bound**: Conformers MUST be classes (the protocol inherits from
  `AnyObject`), because the pane tests the content view controller for
  conformance by a cast.
- **receives-content-spacing**: The `Spacing` the pane passes MUST be the
  app-wide pane-content spacing, `PaneSpacing.contentSpacing` (the four
  pane-content edges, no gutters), and not a spacing carried by the pane or by
  the content.
- **applied-again-on-change**: The pane MUST call `applyPaneSpacing(_:)` again
  whenever a pane-content spacing setting changes (the keys in
  `PaneSpacing.contentSettingKeys`), as well as once when the pane's view loads.
- **pane-pins-flush-for-consumer**: When the content conforms, the pane MUST set
  its own content spacing insets to zero on all four sides, so the content is
  pinned flush to the pane's edges and the gap is applied only by the content.
- **pane-applies-gap-for-non-consumer**: When the content does not conform, the
  pane MUST apply the gap itself, using the spacing's `top`, `leading`, `bottom`
  and `trailing` values as the content's edge constraint constants.
- **applies-once**: The gap MUST be applied exactly once per pane: by the
  content when it conforms, by the pane when it does not, never both.
- **idempotent-assign**: Applying the gap MUST assign, not accumulate, so the
  pane's resolve step is safe to call repeatedly (the source cites
  `idempotency`).
- **no-pane-spacing-of-its-own**: Neither a pane nor its content MAY carry
  spacing of its own; the one source of the gap is the app-wide setting, so every
  pane in every window is spaced alike.
- **consumer-guards-unloaded-view**: The two conformers in the source
  (`PrivateTerminalViewController`, `TerminalSessionContentViewController`)
  MUST return without effect when their view is not loaded, and otherwise MUST
  re-apply their appearance (`reapplyAppearance()`), which is where the
  padding is set.

