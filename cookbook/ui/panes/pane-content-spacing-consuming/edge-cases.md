
- **Spacing of 0 on every edge**: the gap is 0 for both paths (MUST); the
  pane still takes the conforming or non-conforming branch, and the content sits
  flush.
- **Conformance changes after load**: the pane tests conformance at each
  `applyResolvedSpacing()` call, and it takes the gap back off the other path by
  assigning the insets for the current branch (MUST); a pane whose content
  controller is swapped therefore resolves on its next call.
- **Pane with no content**: when the pane's content view controller declined to exist, there are no content edge constraints; `applyResolvedSpacing()` takes the non-conforming branch (the cast fails) and assigns `contentSpacingInsets`, and the constraint assignments do nothing (MUST).
- **Content not yet loaded**: the terminal conformers skip the call when
  `isViewLoaded` is false (MUST); the pane calls again on the next setting change,
  and the pane's own view-load pass calls it once.
- **Negative or very large values**: the source declares the settings as `Int` and
  does no clamping or validation before building the insets (the source leaves
  the range to the settings UI, outside these sources).
- **Spacing argument ignored**: both conformers in the source ignore the
  `spacing` value and re-read their appearance, where the padding is resolved
  (`TerminalAppearance.resolvedPadding` takes `PaneSpacing.contentSpacing` unless the theme's overrides set a side). The
  protocol does not require the conformer to use the value it is given.
- **Legacy terminal padding**: a terminal padding saved before pane-content
  spacing replaced it is carried across by `PaneSpacing.migrateLegacyTerminalPadding`
  (a side already holding a pane-content value keeps it), so a terminal set to 0
  does not jump to 10.
- **Concurrent access**: the protocol and the pane are `@MainActor`, so the
  compiler serializes every call on the main thread.
- **Error states and offline state**: not applicable — no I/O, no dependency that
  could be unavailable, and no operation that can fail.

