
- **Empty or whitespace-only text**: the hook bails early (nothing to split), so
  no spans and no animation (**noop-on-empty-text**).
- **Cursive-joining scripts**: detected via the Unicode `Script=` property set
  `Arabic`, `Syriac`, `Mongolian`, `Nko`, `Mandaic`, `Adlam`
  (`\p{Script=Arabic}|\p{Script=Syriac}|\p{Script=Mongolian}|\p{Script=Nko}|\p{Script=Mandaic}|\p{Script=Adlam}`);
  the string is left rendered normally so joining/shaping isn't broken
  (**skip-cursive-scripts**). Non-joining RTL scripts (e.g. Hebrew) still
  animate, right-to-left.
- **`resetKey` change**: `TextBubble` keys the element by `resetKey` (defaulting to
  `text`) so a text/version change remounts a fresh node instead of reconciling new
  text against imperatively-created spans (which would leave stale split text).
- **Host still animating in**: glyphs are measured in layout space
  (`offsetLeft/offsetTop`), which ignores an ancestor entrance/scale transform, so
  the lens doesn't desync from the glyphs during an entrance animation.
- **Word wrapping**: whole words are wrapped in `inline-block; nowrap` spans and the
  inter-word whitespace stays plain, so breaks only ever happen between words.
- **Compositor pressure**: `will-change` is set only on glyphs currently in the lens
  and cleared as they leave, so only a handful of glyphs are promoted at once.
- **`pauseMs > 0`**: the lens parks (text plain) for `pauseMs` before each sweep;
  the first park is the start delay, later parks are the between-loop pause.

