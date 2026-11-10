
Fixture `items` used by every vector below:

| value | label |
|---|---|
| `sveltekit` | `SvelteKit` |
| `react` | `React` |
| `vuejs` | `Vue.js` |
| `angularjs` | `AngularJS` |
| `solidjs` | `SolidJS` |

`navCount` for this fixture with no filter is 5 (or 6 when the create row is also showing).

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | type-narrows-list | open, type "sv" | filtered list narrows to `SvelteKit` only; the other four items are removed from the visible list |
| T2 | empty-message-when-no-match | `allowCreate=false`, type "zzz" | no options; empty message ("No matches") shown |
| T3 | arrow-roves-highlight, highlight-syncs-into-field | open (no filter), ArrowDown ×2, ArrowUp ×1 | highlight moves index 0 (`SvelteKit`) → 1 (`React`) → 0 (`SvelteKit`); `aria-activedescendant` tracks the highlighted option at each step; field shows the highlighted item's label at each step |
| T4 | enter-accepts-highlighted-item | open, ArrowDown ×1 (highlights `SvelteKit`), Enter | `onChange("sveltekit", { isNew:false })` fired; popover closes |
| T5 | escape-cancels | open, type "test", Esc | no `onChange` fired; listbox closes |
| T6 | enter-accepts-typed-entry | open, type "  Angular  ", Enter | `onChange("Angular", { isNew:true })` fired (text trimmed; "Angular" has no exact case-insensitive match — `AngularJS` is a substring match only); popover closes |
| T7 | pointer-click-commits | open, type "Solid", click create row | `onChange("Solid", { isNew:true })` fired ("Solid" has no exact match — `SolidJS` is a substring match only); popover closes |
| T8 | typed-text-resolves-to-exact-item | open, type "react" (exact case-insensitive match to the `react`/`React` item), Enter | `onChange("react", { isNew:false })` fired — resolves to the item's `value`, not the typed string |
| T9 | create-unavailable-when-disabled | `allowCreate=false`, type "Nope", Enter | no `onChange` fired; nothing happens |
| T10 | ok-mirrors-enter | open, type "Vue", click OK | `onChange("Vue", { isNew:true })` fired ("Vue" has no exact match — the fixture's label is `Vue.js`, not `Vue`); popover closes |
| T11 | cancel-mirrors-escape | open, type "test", click Cancel | no `onChange` fired; popover closes |
| T12 | trigger-opens-surface | click trigger | popover opens |
| T13 | opens-with-field-focused | click trigger | field receives focus (can type immediately) |
| T14 | focused-state-styling | trigger has focus | 2px focus-visible ring visible on the trigger (WCAG 2.4.7) |
| T15 | shift-enter-dismiss-in-keep-open-mode | `keepOpenOnCommit=true`, open, ArrowDown ×1 (highlights `SvelteKit`), Enter, then Shift+Enter | first Enter fires `onChange("sveltekit", { isNew:false })` and popover stays open, with query and highlight reset to their initial (opened) state; Shift+Enter then closes the popover without firing `onChange` |
| T16 | ok-mirrors-enter | open, no filter, no item highlighted | OK button is disabled — trimmed text is empty, so nothing is acceptable yet |
| T17 | focus-returns-on-close | click trigger to open, then Esc | focus returns to the trigger button |
| T18 | (see edge case: Disabling the component) | `disabled=true`, attempt to click/activate the trigger | popover does not open; `aria-expanded` stays `false` |
| T19 | escape-cancels, cancel-mirrors-escape | `keepOpenOnCommit=true`, open, Esc (and, separately, click Cancel) | popover closes without firing `onChange`, same as when `keepOpenOnCommit` is false |
| T20 | arrow-roves-highlight | open (no filter, `navCount=5`), ArrowUp ×1 (from no highlight) | highlight jumps to index 4 (`SolidJS`, the last row); a further ArrowDown ×1 holds at index 4 (no wrap to index 0 or to no-highlight) |
| T21 | highlight-syncs-into-field, type-narrows-list | open, ArrowDown ×1 (highlights `SvelteKit`, field previews "SvelteKit"), then type "x" — the previewed text is not selected, so the keystroke appends to it | highlight clears to no-highlight; field shows "SvelteKitx"; list re-filters by "sveltekitx" (no items match; create row shows) |
| T22 | pointer-click-commits | open (no filter), click the `React` row | `onChange("react", { isNew:false })` fired; popover closes |

