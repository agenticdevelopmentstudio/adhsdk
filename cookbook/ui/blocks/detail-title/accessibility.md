
- **Role**: The title cell is exposed as a heading of level 2 while titled, using `role="heading"` with `aria-level="2"` on a span, so the slot element never changes type; it carries no role while untitled, so an empty strip announces no empty heading.
- **Label**: The heading's accessible name is the title text itself; no separate label prop exists.
- **Heading navigation**: Hoisting a title out of its pane MUST keep that pane's level 2 heading available to heading navigation; source records that losing it broke screen-reader heading navigation and an end-to-end role query for a level 2 heading.
- **State announcements**: Not applicable: the module announces nothing on its own; a changed title is a changed heading text.
- **Keyboard**: Not applicable: the title cell is not focusable and has no key handling in source.
- **Minimum tap target**: Not applicable: the title cell is not an interactive control.
- **title-contrast**: NEEDS REVIEW: Not implemented in source. The title uses the `text-apt-text-muted` token at 12.8px and the source does not state its contrast ratio against the strip background; a token-pair contrast measurement for light and dark themes would settle whether it meets WCAG 1.4.3 (4.5:1 for text this size).

