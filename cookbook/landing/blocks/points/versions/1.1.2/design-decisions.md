
**Decision**: Each list item's content (the optional term plus the detail) is wrapped in a single `<span>` (see **content-span**).
**Rationale**: Each row is a two-column CSS Grid — marker in column one, content in column two. An unwrapped term would land in the grid as its own item and break the intended "marker → lead-in + body" structure instead of flowing inline with the detail.
**Approved**: pending

**Decision**: The `ordered` prop switches both the HTML element (`<ul>` vs. `<ol>`) and the CSS class (`lp-points--ordered`), rather than the class alone (see **ordered-class**).
**Rationale**: The sequence is part of the claim itself ("first this, then that"), and only `<ol>` communicates that to assistive technology — a `ul` announces a bullet where an `ol` announces ordered position. The digits come from a CSS counter rather than content, so a re-ordered source can never disagree with the numbers on screen.
**Approved**: pending

