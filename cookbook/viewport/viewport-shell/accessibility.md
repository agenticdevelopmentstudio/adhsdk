
ViewportShell itself renders no text, interactive elements, or ARIA roles: it is a plain `<div>` wrapper, and accessibility for slotted content is owned by whatever children are placed inside it. Two page-level effects are still the shell's own responsibility:

- It renders a plain, non-interactive `div` with no ARIA attributes, so it introduces nothing for a screen reader or keyboard user to trip over (see **semantic-markup** and **screen-reader-support** in Compliance).
- Locking `html`/`body` to `overflow: hidden` (see **page-lock**) means content taller than the viewport is only reachable if something inside the shell provides its own scrollable region. Neither `ViewportShell` nor `ViewportSpacer` sets `overflow: auto` anywhere in `base.css` — a scrollable child region, if the slotted content needs one, is the consumer's (or a child component's) responsibility to provide (see **keyboard-navigable** in Compliance, `partial`).

