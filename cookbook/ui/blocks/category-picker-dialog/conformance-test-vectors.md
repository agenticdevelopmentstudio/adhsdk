
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | browse-the-full-forest | open with a 2-level forest | roots render; expanding a root reveals its children |
| T2 | filter-by-substring-with-trail | type a substring matching a depth-2 node | that node appears as an option with its "/"-joined ancestor trail |
| T3 | return-a-place-not-a-record, disable-confirm-when-unpickable | open, confirm disabled; click a row, confirm | confirm was disabled with no selection; `onConfirm(nodeId)` fires after the click |
| T4 | offer-a-root-row-only-when-allowed | `allowRoot`, select "Top level", confirm | `onConfirm(null)` |
| T5 | disable-forbidden-rows | `disabledIds=[x]`, click row x | row x stays unselected; confirm stays disabled |
| T6 | cancel-without-confirming | open, click Cancel | `onCancel` fires; `onConfirm` never fires |
| T7 | tree-keyboard-nav | roving stop on a collapsed parent; ArrowRight, ArrowDown, ArrowUp | ArrowRight expands it; ArrowDown moves into its now-visible first child, skipping collapsed siblings; ArrowUp reverses |
| T8 | tree-keyboard-nav | roving stop on an expanded parent's child; ArrowLeft, ArrowLeft again | first collapses the parent; second moves the stop to the parent |
| T9 | tree-keyboard-nav | Home, then End | roving stop moves to the first, then the last, visible row |
| T10 | preselect-initial-id, reset-on-reopen | open with `initialSelectedId="x"`, close, reopen with the same prop | selection starts at x both times; filter/expanded state is empty each open |
| T11 | report-write-errors-inline | `error="conflict"`, `busy` | error text shown above the buttons; field disabled; Cancel/Confirm replaced by a `role="status"` loading spinner — no Cancel/Confirm buttons exist in the DOM |
| T12 | show-empty-messages | `nodes=[]` (browse); a filter matching nothing | "No categories yet."; `No categories match "<text>".` |
| T13 | roving-focus-origin | open with `initialSelectedId` inside a collapsed branch, `allowRoot` unset | roving tab stop is the first top-level category, not the (invisible) preselected node |
| T14 | native-row-activation | focus a row, press Enter (then, on another row, Space) | row selects, identical to a click |
| T15 | filter-field-enter-inert | type a filter, press Enter while focus is still in the field | nothing selects or confirms; focus remains in the field |
| T16 | filter-mode-arrow-nav | type a filter matching several nodes, Tab into the list, ArrowDown twice | roving tab stop moves to the second option, then the third |
| T17 | filter-by-substring-with-trail | type a substring matching a node filed under two parents | exactly one option renders, showing its first (sibling-order) trail |
| T18 | filter-by-substring-with-trail, show-empty-messages | type only spaces into the filter field | browse mode (tree) renders; the "no match" message does not |
| T19 | disable-confirm-when-unpickable | open with `initialSelectedId` naming an id absent from `nodes` | no row renders selected; Confirm's enabled state follows only `disabledIds` membership, so it stays enabled and would call `onConfirm` with the nonexistent id if clicked |
| T20 | disable-forbidden-rows | `disabledIds=[x]`, filter to a hit that includes x | row x renders disabled and unselectable in the option list too |
| T21 | offer-a-root-row-only-when-allowed | open with `allowRoot` unset (default `false`) | no "Top level" row renders; the first visible row is the first top-level category |
| T22 | cancel-without-confirming | press Esc while not busy; then press Esc (and attempt an outside click) while `busy` | not busy: `onCancel` fires; busy: dialog remains open and `onCancel` does not fire either time |
| T23 | preselect-initial-id, disable-confirm-when-unpickable | `allowRoot`, no `initialSelectedId` (default `null`) | "Top level" renders `aria-selected="true"` and `bg-apt-gold/15` on open; Confirm is enabled; clicking it calls `onConfirm(null)` |
| T24 | disable-confirm-when-unpickable | continuing from T23, type any filter text | Confirm becomes disabled (the root row is confirmable only while the filter is empty) |

