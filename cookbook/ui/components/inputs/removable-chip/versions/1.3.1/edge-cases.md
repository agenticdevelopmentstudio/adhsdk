
- **Removal is the consumer's job.** The chip never removes itself; it only calls
  `onRemove`. A typical caller filters the value out of its own list state; the chip
  itself is stateless.
- **Disabled chip:** the ✕ is disabled and `pointer-events-none`, so `onRemove` cannot
  fire; the chip stays put.
- **Missing accessible name:** `removeLabel` is required by the type, but the component
  does not validate its value at runtime — an empty string satisfies the type yet leaves
  the button with no meaningful accessible name. Callers pass a non-empty,
  value-specific label (`Remove ${value}`) so multiple chips have distinct button names.
- **Rich children:** `children` may be more than text (e.g. an avatar + name); it all
  renders inside the badge body inline with the ✕.
- **Empty list:** the chip renders nothing special when a list empties — the consumer
  shows its own empty state.
- **Focus after removal:** removing a chip via keyboard unmounts its remove button,
  which drops the current focus. The consumer SHOULD move focus to the next remaining
  chip's remove button, or back to the input that adds items, so a keyboard user is not
  left with focus lost to the document body. See **keyboard-operable**.

