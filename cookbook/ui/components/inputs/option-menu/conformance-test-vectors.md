
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
| T20 | click-outside-closes-without-commit | open, press the pointer outside the surface | no `onChange`; surface closes |
| T21 | disabled-blocks-interaction | `disabled`, click the trigger and press Enter on it | surface stays closed; `aria-expanded` stays `false` |
| T22 | tab-unsupported | open with `allowOther`, press Tab | focus moves per native order and is not trapped in the surface; selection unchanged |
| T23 | home-end-unsupported | open, ArrowDown once, press Home then End | highlight stays on the second row; no `onChange` |
| T24 | typeahead-unsupported | open, type "S" with the surface focused | highlight does not move; no `onChange` |
| T25 | focus-returns-on-close | open, click a row | `onChange` fires; DOM focus returns to the trigger |
| T26 | keys-act-on-selection | open with `allowOther` and no committed value (input focused, first item highlighted), Enter | commits the first item with `isOther:false`, not the empty Other input |
| T27 | keys-act-on-selection | open with `allowOther` (input focused, first item highlighted), ArrowDown | selection moves to the second item |
| T28 | no-items-no-op-navigation | `items=[]`, `allowOther` false, open, ArrowDown, ArrowUp, Enter | no rows; no `onChange`; surface stays open |
| T29 | other-row-label-inert | open with `allowOther`, click the "Other" label text | no `onChange`; selection and check unchanged |
| T30 | resolves-committed-value | `value` is the Other free text and `allowOther`, open | Other is highlighted and checked; input prefilled with `value` |
