
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| radio-001 | indicate-selection | RadioGroupItem with checked state | Filled `apt-gold` dot visible inside the 16×16px circle |
| radio-002 | hide-indicator-when-unselected | RadioGroupItem with unchecked state | No indicator dot visible |
| radio-003 | single-selection | Two RadioGroupItems in a group; item A is checked, then item B is selected | Item A's indicator disappears as item B's appears; only one item is checked |
| radio-004 | disabled-state | Disabled RadioGroupItem receives a pointer click | Checked state does not change; no selection callback fires |
| radio-005 | disabled-state | Disabled RadioGroupItem holds focus and receives Space or Enter | Checked state does not change; no selection callback fires |
| radio-006 | focus-visible | RadioGroupItem with keyboard focus | `apt-gold` border and 2px ring at 25% opacity visible |
| radio-007 | space-selects | Unchecked RadioGroupItem holds keyboard focus and receives Space | Item becomes checked |
| radio-008 | theme-token-styling | RadioGroupItem in default state | Border color is `apt-border`, background is `apt-bg` |
| radio-009 | color-transitions | RadioGroupItem state change from unchecked to checked | Computed `transition-property` includes `color`/`border-color`/`background-color` and `transition-duration` is greater than 0 |
| radio-010 | no-initial-selection | RadioGroup rendered with neither `value` nor `defaultValue` set | No RadioGroupItem in the group renders its selected indicator |
| radio-011 | value-matches-no-item | RadioGroup's `value` does not match any item's `value` | No RadioGroupItem displays as checked |
| radio-012 | all-items-disabled | Every RadioGroupItem in the group has `disabled` set | No item can be selected via pointer or keyboard; each carries the native `disabled` attribute, `aria-disabled="true"` and `data-disabled`, and renders dimmed through the `disabled:` utilities |
| radio-013 | disabled-item-already-checked | A RadioGroupItem is both checked and disabled | Item shows the selected indicator combined with the disabled item's native `disabled`, `aria-disabled` and `data-disabled` state, dimmed through the `disabled:` utilities |
| radio-014 | boundary-values | RadioGroupItem rendered inside a shrinking flex container | Item stays fixed at 16×16px (`shrink-0` prevents resizing) |

