
- **Reduce Motion**: Not applicable — Rule is a static component with no animation or motion; Reduce Motion preferences do not apply.
- **Increase Contrast**: Rule has no contrast logic of its own, but its stylesheet sets the term text in muted `--lp-accent` (fallback `#9a9a9a`) at `0.68rem` uppercase on a translucent dark background (`--lp-rule-bg`). That small muted text is the weakest contrast in the block and has not been measured here. In a high-contrast mode, a host SHOULD set `--lp-accent` to the full ink color and `--lp-hairline` to an opaque value; native ports SHOULD use the platform's high-contrast text color for terms.
- **Differentiate Without Color**: Not applicable — Rule applies no color-based distinctions; terms differ from details by case, size and letter-spacing as well as color.

