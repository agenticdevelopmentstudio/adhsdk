
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| tag-set-001 | render-combobox, render-entity-chooser, render-chips-row | Render with `label="Tags"`, `noun="tag"`, `options=["foo", "bar"]`, `value=[]`. | Two controls render in the top row; no chips-row element exists below them (see **empty-chips-row-renders-nothing**). |
| tag-set-002 | show-filtered-suggestions | `options=["foo", "bar", "baz"]`, `value=["foo"]`. | Combobox suggestions are filtered to `["bar", "baz"]`; "foo" is not offered. |
| tag-set-003 | accept-exact-match-in-combobox | Precondition `options=["foo", "bar"]`, `value=["foo"]`. The Combobox's text becomes exactly "bar" (typed, or the result of clicking a suggestion — both raise the same `onValueChange` event). | `onChange` is called once with `["foo", "bar"]`. |
| tag-set-004 | clear-combobox-on-acceptance | Precondition `options=["foo", "bar"]`, `value=["foo"]`. Combobox text reaches the exact match "bar" (as in tag-set-003). | Combobox text field is cleared to empty. |
| tag-set-005 | no-create-on-enter | Precondition `options=["foo", "bar"]`, `value=[]`. User types "newlabel" (not an exact match to any option) and presses Enter. | `onChange` is NOT called; the Combobox text remains "newlabel". |
| tag-set-006 | render-chips-from-value | `value=["foo", "bar", "baz"]`. | Three chips render in the chips row, in order: "foo", "bar", "baz". |
| tag-set-007 | remove-chip-on-delete | `value=["foo", "bar", "baz"]`; user clicks remove on chip "bar". | `onChange` is called with `["foo", "baz"]`; the "bar" chip is removed. |
| tag-set-008 | empty-chips-row-renders-nothing | `value=[]`. | No chips-row element exists in the DOM at all — `EntitySelectionChips` renders nothing. |
| tag-set-009 | noun-in-placeholders | `noun="label"`. | Combobox `ariaLabel` is "Add a label" and placeholder is "Add a label…"; EntityChooser `inputLabel` is "Filter or add a label" and placeholder is "Filter or add a label…". |
| tag-set-010 | pass-disabled-to-controls | `disabled=true`. | Combobox, EntityChooser, and `EntitySelectionChips` all receive `disabled={true}`. |
| tag-set-011 | accept-layout-prop | `layout="inline"`. | The shared `Field` component receives `layout="inline"`; the caption renders beside the controls instead of above them. |
| tag-set-012 | options-as-suggestion | `options=["foo", "bar"]`, `value=["foo", "baz"]` (`"baz"` not in `options`). | Combobox suggestions show only `["bar"]`; `"baz"` still renders as a chip (a label created elsewhere). |
| tag-set-013 | maintain-value-order | `value=["third", "first", "second"]` (inserted out of alphabetical order). | Chips render in order: "third", "first", "second" — no sorting is applied. |
| tag-set-014 | display-label | `label="Field Caption"`. | The `Field` wrapper displays "Field Caption" as the row's caption. |
| tag-set-015 | hint-prop | `hint="Help text"`. | The `Field` wrapper displays "Help text" below or beside the caption. |
| tag-set-016 | accept-exact-match-in-combobox, case-sensitive-exact-match | Precondition `options=["bar", "barn"]`, `value=[]`. User types "b", "a", "r" one keystroke at a time. | The instant the text equals "bar" exactly, `onChange` is called with `["bar"]` and the field clears — before the user can continue typing toward "barn". There is no separate select/confirm step; this is the same acceptance path as tag-set-003. |
| tag-set-017 | case-sensitive-exact-match | Precondition `options=["foo"]`, `value=[]`. User types "Foo". | `onChange` is NOT called; `"Foo"` does not exactly equal `"foo"`. The Combobox text remains "Foo". |
| tag-set-018 | case-sensitive-exact-match | Precondition `options=["foo"]`, `value=[]`. User types `" foo "` (leading/trailing spaces). | `onChange` is NOT called; the untrimmed string does not exactly equal `"foo"`. The Combobox text remains `" foo "`. |
| tag-set-019 | pass-label-to-chips | `label="Field Caption"`, `value=["foo"]`. | `EntitySelectionChips` receives `ariaLabel="Field Caption"`. |
| tag-set-020 | pass-label-to-chooser | `label="Field Caption"`. | `EntityChooser` receives `ariaLabel="Field Caption"`. |
| tag-set-021 | accept-classname-prop | `className="custom-class"`. | The `Field` wrapper's root element includes `custom-class` in its class list. |

