
- Each chip is a real `<button type="button">` with `aria-pressed`, so it reads as a toggle
  rather than as a link or a plain button — the pressed state is announced, not merely coloured.
- A chip's accessible name is `"<emoji> <count> on <subjectLabel>"`, and the palette's controls
  are `"React to <subjectLabel>"` and `"React <emoji> to <subjectLabel>"`. The subject is in
  every name because a page shows many bars, and "👍 3" alone does not say which comment.
- The name states the emoji, the count and the subject — never the interaction ("click to…"):
  the role and `aria-pressed` already carry that, and a screen reader would otherwise read the
  instruction on every chip.
- The glyph inside each control is `aria-hidden`, so AT is not told the emoji's CLDR name twice.
- The palette trigger is the `PopoverTrigger` primitive **styled directly**, not a `Button`
  wrapped in one, so there is a single focusable element rather than two nested.
- `busy` disables rather than removes: a bar that dropped its chips mid-write would move the
  pointer's target between the press and the result.

