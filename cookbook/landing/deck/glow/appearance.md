
- **Corner radius**: `border-radius: 50%` — combined with equal width and height, this renders a full circle.
- **Padding**: None — the `lp-glow` CSS class declares no padding.
- **Font**: Not applicable (element contains no text)
- **Background**: `background: var(--lp-glow, radial-gradient(circle, rgba(216, 216, 216, 0.1), transparent 65%))` — a soft light-gray radial gradient at 10% opacity, fading to transparent by 65% of the circle's radius.
- **Foreground/Text**: Not applicable (element contains no text)
- **Border**: None — the `lp-glow` CSS class declares no border.
- **Shadow**: None — the `lp-glow` CSS class declares no `box-shadow`.
- **Min/Max size**: Fixed `width: 62rem` and `height: 62rem`. Positioned `absolute`, `left: 50%`, `transform: translate(-50%, -50%)`, `z-index: -1`, `pointer-events: none`. Default vertical offset is `top: calc(var(--lp-screen-pad-top, clamp(5.5rem, 14svh, 9rem)) + 9rem)`; inside a hero (`.lp-screen--center`) it is instead `top: calc(50% + (var(--lp-hero-pad-top, 6.5rem) - var(--lp-hero-pad-bottom, var(--lp-dock-clear, 0px))) / 2)`.

