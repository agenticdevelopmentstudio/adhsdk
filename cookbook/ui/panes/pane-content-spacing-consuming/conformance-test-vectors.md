
The source of the protocol has no tests beside it. The only test that touches the
spacing settings is `PaneSpacingMigrationTests`, which covers the legacy terminal
padding migration, not this protocol, so these vectors are derived from the
protocol, `PaneViewController.applyResolvedSpacing()` and the two conformers.

| ID | Requirements | Input | Expected |
|---|---|---|---|
| pane-spacing-001 | pane-pins-flush-for-consumer, applies-once | pane whose content conforms; pane-content spacing 10 on every edge | the content's `applyPaneSpacing` is called with the spacing; the pane's `contentSpacingInsets` is zero on all four sides and its content edge constraint constants are 0 |
| pane-spacing-002 | pane-applies-gap-for-non-consumer, applies-once | pane whose content does not conform; top 4, leading 6, bottom 8, trailing 10 | `contentSpacingInsets` is top 4, left 6, bottom 8, right 10 and the four content edge constraint constants take those values |
| pane-spacing-003 | receives-content-spacing | conforming content; settings top 2, leading 3, bottom 4, trailing 5 | `applyPaneSpacing` receives a `Spacing` with top 2, leading 3, bottom 4, trailing 5 and both gutters 0 |
| pane-spacing-004 | applied-again-on-change | conforming content already applied; `pane_content_spacing_top` changes | `applyPaneSpacing` is called a second time |
| pane-spacing-005 | applied-again-on-change | any pane; a setting outside `PaneSpacing.contentSettingKeys` changes (for example a frame spacing key) | no new call to `applyPaneSpacing` and no change to the content constraints |
| pane-spacing-006 | idempotent-assign | non-conforming content; `applyResolvedSpacing()` called three times with the same settings | `contentSpacingInsets` and the constraint constants are the same after the third call as after the first |
| pane-spacing-007 | pane-pins-flush-for-consumer | pane that applied a gap for non-conforming content, then its content is replaced by a conforming one and `applyResolvedSpacing()` runs | the insets and constraint constants return to 0 |
| pane-spacing-008 | consumer-guards-unloaded-view | `TerminalSessionContentViewController` whose view is not loaded | `applyPaneSpacing(_:)` returns with no effect; `reapplyAppearance()` is not called |
| pane-spacing-009 | consumer-guards-unloaded-view | `PrivateTerminalViewController` whose view is loaded | `applyPaneSpacing(_:)` calls `reapplyAppearance()` |

