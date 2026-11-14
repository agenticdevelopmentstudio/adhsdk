
- **Empty or undefined subject** (see **empty-subject-no-suffix**): When subject is not provided or is an empty string, component MUST render button labels and group aria-label without a trailing subject suffix (e.g., "Move up" instead of "Move up "). Component MUST handle this gracefully without extra whitespace.
- **Rapid clicks while busy** (see **busy-click-guard**): If the user clicks a button multiple times while busy is true, onMoveUp and onMoveDown MUST NOT be called; the click handler's busy guard prevents all invocations.
- **Both moves disabled (boundary edge case)** (see **both-boundaries-disabled**): If both canMoveUp and canMoveDown are false (hypothetically, in a single-item list), both buttons MUST render as disabled. Component MUST not error.
- **Transition from busy to not busy** (see **busy-to-idle-recovery**): When busy transitions from true to false, component MUST restore full opacity and re-enable interaction; aria-disabled and aria-busy MUST be removed or set to undefined.
- **Very long subject text**: If subject is a long string, component MUST not truncate or wrap it in the aria-label; the full text is included in the label (truncation is the consuming component's responsibility if needed).

