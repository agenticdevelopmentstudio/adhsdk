
`EntityChooser` is a browse / filter / select / add surface for a list of string
entities — the account's categories or tags. It is a thin composition over
`ListChooser` (`@adh-sdk/ui/components/list-chooser`), which supplies the
disclosed, text-filtered list with a roving keyboard highlight and an "add a new
one" affordance. `EntityChooser` adds only the **selection semantics** on top:

- **single** mode is a one-value picker — selecting (or creating) replaces the
  value, exposed through a unified `string | null` callback.
- **multi** mode maintains an ordered **set**, rendered as removable chips beside a
  `Choose…` trigger whose browser stays open across accepts, so one open can add as
  many entries as needed. Already-selected options are hidden from the browser, so
  a member can't be added twice.

It never re-implements the list or keyboard logic — that lives in `ListChooser`. It
is the editor half of the `[Combobox autocomplete] [Choose…]` field pattern, where a
`Combobox` does inline typeahead and `EntityChooser`'s trigger opens the full
browse/add surface over the same options. It differs from `RecipientInput` (a free-text chip input with no backing
option list or filtered browser) and from `ListChooser` (single-value only, no chip
set, value-bearing trigger).

