
- **renders-one-chip-per-tally**: The component MUST render exactly one chip per entry in `reactions`, in the order given — it MUST NOT sort, merge or filter them.
- **chip-shows-emoji-and-count**: Each chip MUST show its emoji and its count.
- **chip-is-a-toggle**: Activating a chip MUST invoke `onToggle` with that chip's emoji, whether or not the viewer has already reacted with it.
- **announces-own-reaction**: A chip whose `mine` is true MUST carry `aria-pressed="true"`, and a chip whose `mine` is false MUST carry `aria-pressed="false"`.
- **stateless-tallies**: The component MUST NOT change a count or a `mine` flag itself; it only signals `onToggle`, leaving the write and the re-read to the consumer.
- **palette-offers-choices**: The component MUST render a palette trigger that opens a popover offering `choices` (default `DEFAULT_REACTIONS`).
- **palette-uses-the-same-toggle**: Picking an emoji from the palette MUST invoke `onToggle` with that emoji — the same call a chip makes — and MUST close the popover.
- **palette-offers-everything**: The palette MUST offer every entry in `choices`, including emoji already present on the subject, so it never has to explain an absence.
- **busy-goes-inert**: When `busy`, every chip and the palette trigger MUST be disabled, and the bar MUST keep rendering the same chips in the same order.
- **disabled-hides-the-way-in**: When `disabled`, the counts MUST still render, every chip MUST be disabled, and the palette trigger MUST NOT render at all.
- **names-the-subject**: Every control's accessible name MUST include `subjectLabel`, so two bars on one page are distinguishable.
- **glyph-is-decorative**: The emoji glyph inside a control MUST be `aria-hidden`, leaving the control's `aria-label` as its sole accessible name.

