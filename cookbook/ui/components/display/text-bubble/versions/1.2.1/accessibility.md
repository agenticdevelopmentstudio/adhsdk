
- The text content is real and remains available to assistive technology: while
  animating, an off-screen (visually clipped) span carries the full string, and
  the visible per-glyph copy is `aria-hidden`, so screen readers read the whole
  phrase, not a stream of single letters.
- When inactive the element is simply plain text — fully selectable and crawlable.
- The effect is decorative and never conveys information; disabling it (via
  `active={false}`) removes all motion while leaving the message intact. The
  component does not itself detect `prefers-reduced-motion`; hosts MAY gate
  `active` on it (see **Design Decisions**).
- Cursive-joining scripts are deliberately left un-split so their letter shaping
  (which depends on joining) is not broken.

