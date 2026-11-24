
- The syntax list is a fixed, hard-coded reference (no props feed it), so the
  content never varies between consumers — one authoritative cheatsheet.
- Fenced-code and list snippets contain newlines; the `<code>` uses
  `whitespace-pre-wrap` so multi-line snippets render literally.
- `side` / `align` are forwarded to the popover positioner; near a viewport edge
  the shared primitive flips/clamps the popover to stay on screen.
- Re-opening after dismissal re-mounts fresh content (the control is stateless).

