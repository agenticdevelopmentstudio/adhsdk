
- **Empty children**: When no children are provided, the component renders an empty `lp-split` container; this is not an error state. See split-008.
- **Single child**: When only one child is provided, the component renders it within the split container; the single-column layout renders it normally, and in the two-column layout the second grid cell is simply empty — the column ratio and breakpoint are unaffected by child count. See split-009.
- **Empty or undefined className**: `className` is typed `string | undefined`, never `null`. When it is `undefined` or `""`, the component does not append an empty class token or trailing whitespace; only `lp-split` (or `lp-split` plus a non-empty `className`) is applied. See split-007.
- **Viewport resize**: The component responds to dynamic viewport resizes (e.g., orientation change, window resize) via the CSS media query at `62rem`; no JavaScript-based resize listener is implemented. See split-004.
- **Very wide viewports**: No maximum width is enforced, by design — the `fr`-based column tracks scale to fill the available width in a `5:6` ratio. Capping the overall width is the parent's responsibility (for example, composing `Split` inside `Wrap`, which constrains the content column). See split-010.
- **Very narrow viewports**: Below the `62rem` breakpoint the component stacks to a single column with no minimum width enforced. See split-011.
- **RTL directionality**: `Split` sets no explicit `direction`, so CSS Grid's native direction-aware column placement mirrors the two-column layout under an ancestor `dir="rtl"` without any component-level code; this is not yet exercised by an automated test. See split-006 and Localization.

