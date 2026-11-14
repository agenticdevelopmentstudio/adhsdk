
- **render-a-dot-per-row**: `StatListRow` MUST render a decorative `StatusDot` (size 7, no accessible label) at its `tone` as the row's leading glyph.
- **truncate-the-label**: `StatListRow` MUST render `label` so it clips with an ellipsis when it overflows the row's available width, flexing to claim the remaining space, and MUST set its native `title` to `labelTitle` when provided, so a clipped label is still readable on hover.
- **right-align-trailing**: When `trailing` is not `null`/`undefined` — a falsy-but-present value such as `0` still counts as provided — `StatListRow` MUST render it right-aligned and non-shrinking after the label; when `trailing` is `null` or `undefined`, it MUST render no trailing slot.
- **honor-row-element**: `StatListRow` MUST render as a `li` when `as="li"` and a `div` otherwise, so a semantic list uses `ul`/`li`.
- **stack-rows**: `StatList` MUST arrange its children in a single vertical column with consistent spacing between rows and no list-marker bullets.
- **divide-when-asked**: `StatList` MUST add a top divider (border + padding) when `divided` is set (the list sits under card content) and MUST omit it otherwise.
- **honor-list-element**: `StatList` MUST render as a `ul` when `as="ul"` and a `div` otherwise.
- **spread-host-attributes**: Both MUST spread remaining host attributes (`data-*`, `id`, handlers) onto their root element so hosts can tag them (e.g. the fleet `data-testid="down-list"`).
- **as-consistency**: Neither component checks the other's `as`, so a caller SHOULD use `as="li"` rows only inside an `as="ul"` StatList (and `as="div"` rows only inside an `as="div"` StatList) to keep list semantics valid; see also **honor-row-element** and **honor-list-element**.

