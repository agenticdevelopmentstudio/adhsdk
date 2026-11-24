
- **Created multi entry already present.** A typed entry equal to an existing member is rejected by the dedupe guard even though it's hidden from the list, so a stale type can't duplicate it.
- **Single free text vs. option.** A single `value` that matches no option still shows on the trigger as free text (inherited from `ListChooser`'s value resolution).
- **Empty options.** With no options, an empty filter shows `ListChooser`'s empty message; typing surfaces the create row when `allowCreate`.
- **Trigger label vs. value.** In multi mode the trigger always reads the trigger label (the inner `ListChooser` value is held at `null`); in single mode it reflects the chosen value.
- **Multi selectionPlacement host mode.** When `selectionPlacement="host"`, the chooser renders only the trigger (`w-auto` removed, `className` applied to trigger); the caller owns rendering `EntitySelectionChips` alongside and manages the selected values independently.

