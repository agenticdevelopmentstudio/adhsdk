
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | renders-combobox-role | render | input has `role="combobox"`, `aria-expanded="false"` |
| T2 | type-reveals-suggestions | set query "Vu", open | only "Vue" shown; non-matches absent |
| T3 | aria-controls-listbox | open | input `aria-controls` equals the listbox id |
| T4 | arrow-moves-active, enter-picks-active | open "S", ArrowDown, Enter | `aria-activedescendant` → "Svelte"; value becomes "Svelte"; popup closes |
| T5 | escape-closes | open "V", Esc | `aria-expanded="false"`; value unchanged from before Esc |
| T6 | empty-shows-message | set query "zzz", open | empty message shown; no options |
| T7 | controlled-value | edit text | `onValueChange` fires with the new text |
| T8 | pointer-pick | open "Ap", pointer click the "Apple" row | value becomes "Apple" via `onValueChange`; popup closes |
| T9 | disabled-inert | render with `disabled`, press ArrowDown, then type a character | popup does not open; input does not receive the keystroke |
| T10 | current-value-marked | set `value` to "Vue", open | the "Vue" row shows a check mark; other rows do not |

