
`OptionMenu` is a single-select "popup menu": a trigger button that discloses a
list of choices with full keyboard navigation, plus an optional editable
**"Other"** item as the last entry. It is a general-purpose popup menu for forms
(example: a "How did you hear about us?" field with a free-text fallback). It
is built by composing existing primitives — `Popover` (surface), `Input` (the
Other field), `Button` (the OK affordance) — with a hand-managed roving
**selection** so the keyboard model below is exact. It deliberately does **not**
build on `DropdownMenu` / Base-UI menu: menu roles hijack typeahead and focus and
fight an embedded text input. It is distinct from the rail filter `PopupMenu`
block (`@adh-sdk/ui/blocks/popup-menu`), which keeps its own `allLabel`/`onNew`
filter semantics and is unchanged.

