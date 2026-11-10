
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | add-row-on-enter-or-button | Type a name, press Enter in a field | Row appended to staged table; entry cleared; Name refocused |
| T2 | add-row-on-enter-or-button | Activate the entry **Add** button (click, not Enter) with a valid entry | Row appended to staged table; entry cleared; Name refocused |
| T3 | ignore-blank-entry | Empty entry, press Enter / activate Add | No row added (no-op) |
| T4 | ignore-blank-entry | Entry has only an admin note (name/email/phone blank), press Enter / activate Add | No row added (no-op); note remains in the field, not cleared |
| T5 | disable-footer-add-when-empty | 0 staged rows | Footer Add disabled |
| T6 | disable-footer-add-when-empty | ≥1 staged row | Footer Add enabled |
| T7 | disable-footer-add-when-busy | `busy=true` | Footer Add disabled |
| T8 | call-onadd-and-close | Footer Add with staged rows | `onAdd(stagedRows)` called; internal state resets; `onClose()` called immediately |
| T9 | confirm-cancel-when-dirty | Cancel with staged rows or entry content | Discard-confirm `UnsavedChangesAlert` opens |
| T10 | confirm-cancel-when-dirty | Esc with staged rows or entry content | Discard-confirm `UnsavedChangesAlert` opens |
| T11 | confirm-cancel-when-dirty | Backdrop click with staged rows or entry content | No-op: backdrop click is inert (shared `Dialog`'s `disablePointerDismissal`); dialog stays open, no confirm opens |
| T12 | confirm-cancel-when-dirty | Cancel with empty table and empty entry | Closes immediately, no confirm |
| T13 | confirm-cancel-when-dirty | `busy=true`, Cancel activated with a dirty state | Discard-confirm `UnsavedChangesAlert` opens; `busy` does not disable Cancel |
| T14 | tab-order | Tab from Note | Focus lands on the Add button |
| T15 | confirm-cancel-when-dirty | Add rows, discard via `UnsavedChangesAlert`, then reopen (`open=true` again) | Staged table and entry fields are empty (state was reset on close) |

