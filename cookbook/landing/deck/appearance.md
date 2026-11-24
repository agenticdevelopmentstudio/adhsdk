
Deck draws nothing itself (no border, background or box), but mounting it changes how the whole document looks and scrolls, through document-level rules keyed on its base style hook (see #requirements/document-gate):

- **Root type size**: the document's root font size is set to a percentage slightly under the browser default, which scales all rem-sized content together.
- **Horizontal clip**: the document and body clip horizontal overflow, and the scrollbar gutter stays stable.
- **Scroll snapping**: once the host's script arms it, the document snaps vertically to each screen with mandatory snapping.
- **Page base style**: the body takes the site's ground colour, ink colour, font and line height.

Further visual styling is defined by CSS rules applied to the `.lp-deck` class or to its children.
