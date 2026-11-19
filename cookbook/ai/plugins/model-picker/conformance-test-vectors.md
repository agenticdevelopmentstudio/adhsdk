
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| model-picker-001 | single-presentation-path, transient-popover | Present the chooser for a control's caret | A transient popover points at the caret; no window titled for the chooser exists; the chooser has no OK or Cancel button |
| model-picker-002 | search-field-focus | Present the chooser | The search field is first responder |
| model-picker-003 | opens-on-current-model | Context current model `fast`, which resolves to `acme-fast-2` | The `acme-fast-2` row is selected; the choice callback has not been called |
| model-picker-004 | select-chooses-and-stays-open | Open with `m1` current; click the `m2` row | The choice callback is called once with `m2`; the popover is still shown |
| model-picker-005 | return-chooses-and-closes | Open; arrow down to `m3`; press Return | The callback receives `m3` (once for the arrow move, not again for Return); the popover is closed |
| model-picker-006 | escape-or-outside-closes | Open with `m1` current; press Escape | The popover is closed; the callback was never called |
| model-picker-007 | chooses-only-visible-rows | Type a query matching no model; press Return | The callback is not called |
| model-picker-008 | alias-kept-when-unchanged | Context current model `fast`; select another row, then double-click the `acme-fast-2` row | The last value the callback receives is `fast` |
| model-picker-009 | large-model-confirmation | A local model in the warn tier; click its row, then decline the confirmation | The callback is not called for it; the previously chosen model stays chosen; the popover is still shown |
| model-picker-010 | large-model-confirmation | A local model in the block tier; click its row | No confirmation is shown; the callback receives that model |
| model-picker-011 | control-name-text, control-default-label | Display name closure returns none | The control reads `AI Model ⌄ : Choose a Model` |
| model-picker-012 | control-opens-chooser | Click the name button | The chooser opens anchored to the caret with the context closure's current value |
| model-picker-013 | control-forwards-choice | The chooser reports `m2`; the display-name closure now returns "Model Two" | The caller's choice closure receives `m2`; the name button reads "Model Two" |
| model-picker-014 | control-disabled-without-context | Context closure returns none; click the caret | Both buttons are disabled; nothing is presented |
| model-picker-015 | one-chooser-at-a-time | Present for control A, then present for control B | Only B's popover is shown |
| model-picker-016 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

