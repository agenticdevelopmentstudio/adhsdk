
- **Empty or undefined subject**: no trailing space or suffix on any label (see **empty-subject-no-suffix**).
- **Rapid clicks while busy**: none reach `onMoveUp` or `onMoveDown` (see **busy-click-guard**).
- **Both moves disabled** (a single-item list): both buttons render disabled, with no error (see **both-boundaries-disabled**).
- **Transition from busy to not busy**: full opacity and interactivity return, and the busy attributes are removed (see **busy-to-idle-recovery**).
- **Very long subject text**: the full text goes into every label (see **subject-not-truncated**).
