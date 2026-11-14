
- **Decision**: The button-row layout is driven by the container's own width and the
  buttons' content, not a viewport media query.
  **Rationale**: A media query can only see the viewport, not the width the row
  actually has inside its container, which is what determines whether both buttons
  fit at natural width.
  **Approved**: pending

- **Decision**: The equal-vs-natural rule is resolved in CSS (`flex-1 max-w-max` in a
  `justify-end` row), not measured and flipped in JavaScript after mount.
  **Rationale**: A prior implementation rendered the row equal-width, then read each
  button's natural width in a layout effect by moving it to `position: fixed; left:
  -9999px`, and flipped the row via `setState`. Reading `getBoundingClientRect()`
  mid-effect forced a reflow, which gave each button a resolved *previous* width and
  so armed `Button`'s `transition-all`; the flip became a ~150ms animation that
  started only once the dialog was already on screen and clickable. Instrumented in
  Chromium, Cancel travelled 268px to the right while shrinking from 198px to 64px —
  and it held the wrong position for four frames (55ms → 122ms) before the slide
  began, long enough to look settled. A click aimed there landed on bare dialog
  surface after the button had left, and the dialog just sat there, apparently
  ignoring you. It surfaced as a rare e2e flake; it was a real defect for anyone
  quick with a mouse. The general lesson: deciding your own layout after you are
  already interactive is a race with your user — a declarative rule the engine
  resolves before the first paint has no such window.
  **Approved**: pending

- **Decision**: No layout helper (the old `decideActionLayout(containerWidth,
  maxButtonWidth)`) is exported.
  **Rationale**: That helper existed so the equal/natural threshold could be
  unit-tested without a real layout. With the rule expressed in CSS there is no
  threshold left to test in isolation — the contract is now the class list
  (asserted in unit tests) plus the settled geometry (asserted in the browser).
  **Approved**: pending

- **Decision**: Non-destructive confirmations default initial focus to Confirm;
  destructive ones default it to Cancel.
  **Rationale**: An accidental Enter should not trigger a dangerous confirm, so the
  safe button is focused by default. `focusOnMount={false}` yields focus to hosts
  that want to focus a form field instead.
  **Approved**: pending

- **Decision**: A destructive dialog's default-focused Cancel button uses the
  `--apt-text` (on-surface foreground) focus ring instead of the theme's accent
  ring.
  **Rationale**: `Button`'s default focus ring resolves `--ring` to the accent
  color, which is right for a ring the user asked for by tabbing but wrong for one
  painted by us on mount, before the user has chosen anything. Several themes'
  accents are red (`gruvbox`, `monokai`, `terminal-split` among them), and a
  destructive dialog is the only kind that focuses Cancel by default, so on those
  themes the safe button would wear the same alarm color as the destructive button
  beside it — inverting the one signal the pair exists to carry. `--apt-text` is
  guaranteed to contrast with the dialog's surface in every theme and is not a
  color any theme uses to mean danger.
  **Approved**: pending

- **Decision**: Rendering the spinner in place of both buttons (rather than
  disabling them) is how `busy` is handled.
  **Rationale**: Replacing the buttons keeps the in-flight state simple to reason
  about and prevents a double-submit; there is no disabled-button state that has to
  stay synchronized with the spinner.
  **Approved**: pending

- **Decision**: `confirmDisabled` defaults to `false`.
  **Rationale**: The prop exists to support dirty-gating (e.g. disabling Save until
  a form changes), but defaulting it to `true` would change the behavior of every
  existing caller, which expects confirm to be enabled whenever the dialog is idle.
  **Approved**: pending

- **Decision**: When `confirmDisabled` flips to `true` while the confirm button
  holds focus, the component does not move focus away.
  **Rationale**: The focus-placement effect runs once, on mount (its deps are
  `focusOnMount` and `initialFocus`), by design — re-running it whenever
  `confirmDisabled` changes would risk yanking focus out from under whatever the
  user is doing elsewhere in the dialog. Moving focus reactively on every
  disablement is left to the host, which already owns the surrounding dialog's
  focus semantics (see the "Confirm disabled while button has focus" edge case).
  **Approved**: pending

