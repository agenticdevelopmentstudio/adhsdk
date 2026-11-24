
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | arrow-nav-clamps, enter-commits-list-item | open, ArrowDown ×2, Enter | the right item commits, surface closes |
| T2 | escape-closes-without-commit | open, Esc | no `onChange`; trigger refocused |
| T3 | pointer-click-commits | click a row | that row commits, closes |
| T4 | other-input-focused-on-open | open with `allowOther` | Other input is focused |
| T5 | ok-enabled-when-nonempty | type into Other | OK enabled; empty → disabled |
| T6 | typing-moves-check-to-other | type into Other | check moves to Other |
| T7 | enter-commits-other-when-nonempty | type "Foo", Enter | commits "Foo" with `isOther:true` |
| T8 | arrowup-from-other-moves-to-list | ArrowUp from Other input | selection to last list item; input blurred |
| T9 | resolves-committed-value, check-marks-committed-value | controlled `value` = an item | that item resolves checked |
| T10 | resolves-committed-value, check-marks-committed-value | controlled `value` = Other free text | Other checked, input prefilled |
| T11 | trigger-opens-on-activation | trigger focused and closed, Enter (also Space, ArrowDown) | surface opens |
| T12 | focus-returns-on-close | open, Escape | no `onChange`; DOM focus returns to the trigger |
| T13 | selection-not-commit | open, ArrowDown to move the highlight, no further key | no `onChange` fired |
| T14 | arrowdown-from-last-item-to-other | open with `allowOther`, ArrowDown to the last list item, ArrowDown again | selection moves to Other; input re-focused |
| T15 | enter-noop-when-other-empty | Other active, input empty, Enter | no `onChange`; surface stays open |
| T16 | ok-equals-enter-for-other | type "Foo" into Other, click OK | commits "Foo" with `isOther:true`, identical to Enter (T7) |
| T17 | arrow-nav-clamps | open (no `allowOther`), ArrowUp while the first item is highlighted | highlight stays on the first item (no wrap) |
| T18 | arrow-nav-clamps | open (no `allowOther`), ArrowDown while the last item is highlighted | highlight stays on the last item (no wrap) |
| T19 | open-initializes-selection | open with a committed item, before any key press | that item is highlighted immediately (independent of T9's check) |

