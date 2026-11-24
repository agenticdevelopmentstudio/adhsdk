
The component renders a plain native `<button>` (it does not wrap a shared button
component). It sets no inline styles itself; all of the below come from its own
optional, separately-published stylesheet (`appearance-mode-toggle.css`, keyed to the
`awt-appearance-mode-toggle*` classes the component emits) — a consumer that does not
import it gets an unstyled native button instead.

- **Corner radius**: `0.375rem`, via the optional stylesheet's `border-radius`; native
  browser button default if the stylesheet is not imported.
- **Padding**: `0.5rem`, via the optional stylesheet; native default otherwise.
- **Font**: Not set by the component or its stylesheet; inherits the ambient/browser
  default button font.
- **Background**: `transparent`, via the optional stylesheet (unchanged on hover and
  focus); native button chrome otherwise.
- **Foreground/Text**: Icon rendered inline, uses `currentColor` for stroke. The
  optional stylesheet sets the button's `color` to `var(--color-text-dim)` by default
  and `var(--color-text-primary)` on `:hover`, so the icon's inherited color changes
  with hover; without the stylesheet, `currentColor` resolves to the native button
  text color instead.
- **Border**: `border: 0`, via the optional stylesheet; native default otherwise.
- **Shadow**: Not specified by the component or its optional stylesheet.
- **Focus ring**: A `2px solid var(--color-accent)` outline with `2px` offset on
  `:focus-visible`, via the optional stylesheet — added on top of (not replacing) the
  native button's default focus handling; see States (Focused).
- **Transition**: `color` only, `150ms ease` (`var(--awt-transition, 150ms ease)`), via
  the optional stylesheet; no other property transitions.
- **Min/Max size**: Not specified by the component. Icon has `viewBox="0 0 24 24"` and
  is sized `1.25rem × 1.25rem` (20×20px) by the optional stylesheet's `__icon` class;
  the badge icon is `0.625rem × 0.625rem` (10×10px) via `__badge-icon`. Overall button
  size is not fixed — it follows content plus padding (and any host CSS).

