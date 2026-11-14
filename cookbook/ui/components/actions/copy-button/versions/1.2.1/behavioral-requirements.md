
- **copies-gettext-at-click**: The component MUST call `getText()` when clicked and write its result to the clipboard via `navigator.clipboard.writeText`.
- **reflects-current-selection**: Because it invokes `getText()` only on click, the component MUST copy the text current at the moment of the click, not a value captured at render.
- **skips-empty-text**: When `getText()` returns the empty string `""`, the component MUST NOT write to the clipboard and MUST NOT flash success. `getText()`'s result is used as a JavaScript truthiness check (`if (text)`), not trimmed, so a whitespace-only string (e.g. `" "`) is truthy and MUST be copied normally — only the exact empty string counts as "nothing to copy".
- **flashes-success-check**: On a successful copy, the component MUST swap the clipboard glyph for a check icon and tint it `apt-green`.
- **idle-title-from-label**: While idle (no active success flash), the component MUST set its `title` to the current value of `label`.
- **sets-copied-title**: On a successful copy, the component MUST set its `title` to `"Copied!"`.
- **reverts-after-timeout**: The component MUST revert the check, the green tint, and the title back to the idle state 1200 ms after a successful copy.
- **swallows-copy-failure**: When the clipboard write rejects (insecure context or denied permission), the component MUST NOT enter the success state and MUST NOT throw.
- **labels-from-prop**: The component MUST expose `label` as its accessible name via `aria-label`.
- **decorative-icon**: The component MUST mark its glyph `aria-hidden` so the accessible name comes solely from `label`.
- **forwards-classname**: The component MUST merge a consumer `className` onto the button element via `cn()`.

