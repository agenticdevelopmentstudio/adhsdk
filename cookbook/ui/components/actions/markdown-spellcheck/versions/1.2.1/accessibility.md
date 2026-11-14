
- The toggle is a real `<button>` whose accessible name is the `label`
  (default `Check spelling`) and whose on/off state is exposed via
  `aria-pressed`.
- The panel is a shared `Popover`, so it inherits Escape + outside-click
  dismissal and focus restore to the toggle.
- The problem list is a semantic `<ul>` labelled `Spelling and grammar issues`;
  each apply action is a real `<button>` (keyboard operable) with an
  `aria-label` of the form `Replace "<flagged>" with "<suggestion>"`, so the
  action is unambiguous out of context.
- harper's `message()` is rendered as plain text (never HTML), so untrusted lint
  text cannot inject markup.
- Loading uses the shared `Spinner` (`role="status"`); the error state pairs an
  `aria-hidden` icon with literal text.

