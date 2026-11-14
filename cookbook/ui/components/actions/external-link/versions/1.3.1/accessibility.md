
- **Accessible name = children.** The link's name comes from its text content;
  the `↗` glyph is `aria-hidden`, so a link reading "PostHog ↗" is named
  "PostHog", not "PostHog up-right arrow".
- **Keyboard focus is visible.** `focus-visible:ring-2 ring-apt-gold/40` gives a
  clear focus indicator without a persistent outline on mouse click.
- **New-tab safety.** `rel="noopener noreferrer"` is always present, closing the
  reverse-tabnabbing hole that a bare `target="_blank"` would open.
- **Leading-icon mode.** In `glyph={false}` usage the visible icon is itself
  `aria-hidden`, and the visible label text (e.g. "GitHub") remains the
  accessible name — so dropping the trailing arrow never removes the link's name.
- The component does not auto-announce "opens in a new tab"; consumers for whom
  that matters SHOULD add it (e.g. via visually-hidden text) at the call site.

