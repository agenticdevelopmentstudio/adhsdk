
- **Null or undefined children**: The root element always renders regardless of `children`; there is no case where the component itself does not render. React renders `null`/`undefined` children as nothing, so the rendered output is the root element plus, if `glow: true`, the Glow component. See screen-014.
- **Empty children array**: An empty array renders the same as `null` or `undefined` — nothing — so the root element renders with no additional content. See screen-015.
- **Glow with no children**: Component MUST render Glow when `glow: true`, independent of whether `children` is null, undefined, or empty; Glow's presence depends only on the `glow` prop. See screen-011.
- **Multiple class collisions**: If `className` contains `lp-screen` or `lp-screen--center`, the merge logic (see **merge-classname**) concatenates all classes without deduplication, producing a class list with duplicate tokens; a DOM `classList` treats duplicate tokens as a no-op, and host stylesheet SHOULD rely on CSS cascade to manage any remaining style conflicts. See screen-008.

