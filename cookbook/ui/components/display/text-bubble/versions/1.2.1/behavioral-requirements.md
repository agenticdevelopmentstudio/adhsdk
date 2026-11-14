
- **render-plain-text**: When `active` is false, the component MUST render `text` as ordinary, selectable text content in the host element.
- **decorative-when-inactive**: When `active` is false, the component MUST leave the text un-split and un-animated (plain).
- **animate-lens-when-active**: When `active` is true, the component MUST run a lens that sweeps the glyphs in reading order and restarts from the beginning (a forward loop).
- **scale-and-blur-under-lens**: The component MUST magnify (up to `1 + maxScale`) and blur (up to `maxBlur`) each glyph in proportion to its nearness to the lens centre, and MUST leave glyphs outside `radius` untouched.
- **color-shift-under-lens**: The component MUST shift each in-lens glyph's colour from `colorFrom` toward `colorTo` in proportion to its nearness to the lens centre.
- **preserve-accessible-text**: While animating, the component MUST keep the full string available to assistive technology and MUST mark the visible per-glyph copy `aria-hidden`.
- **restore-on-cleanup**: On unmount, on `active` becoming false, or on a `resetKey` change, the component MUST restore the element's original plain text.
- **follow-text-direction**: The lens MUST travel left-to-right for `ltr` elements and right-to-left for `rtl` elements, top line to bottom line.
- **skip-cursive-scripts**: For text containing cursive-joining scripts — the Unicode `Script=` values `Arabic`, `Syriac`, `Mongolian`, `Nko`, `Mandaic`, `Adlam` (matched by `\p{Script=Arabic}|\p{Script=Syriac}|\p{Script=Mongolian}|\p{Script=Nko}|\p{Script=Mandaic}|\p{Script=Adlam}`) — the component MUST leave the text rendered normally and MUST NOT split it into per-character spans.
- **not-break-words-at-wrap**: The component MUST only allow line breaks between words (never mid-word) when it splits the visible copy into glyphs.
- **remeasure-on-resize**: The component MUST re-measure glyph positions and re-read direction when the host element rewraps on resize.
- **noop-on-empty-text**: When `active` is true and `text` is empty or whitespace-only, the component MUST NOT build spans or animate.

