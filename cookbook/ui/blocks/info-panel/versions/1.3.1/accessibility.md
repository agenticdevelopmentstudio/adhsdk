
- The panel renders as a `<section>` with an accessible name: `ariaLabel` when
  given, else the `title` when it is a string, so the panel is a labeled landmark
  region.
- The leading `icon` is decorative and marked `aria-hidden`, so assistive tech reads
  the title rather than an unlabeled glyph.
- In scroll mode the body is a real scroll container (`overflow-y-auto`). The
  source gives the div itself no `tabIndex`, so keyboard reachability depends on
  focusable content the host renders inside it — not every browser makes an
  unfocusable overflow container keyboard-scrollable on its own (see
  **keyboard-navigable** in Compliance).
- Color and contrast come from the `apt-*` theme tokens, consistent across light and
  dark themes and every site.

