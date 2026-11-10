
- **Indent spacing**: `1.25em` per nesting level (computed inline as `depth * 1.25em` inline-start padding).
- **Toggle button**: No visible background at any state; the icon/text color and focus ring communicate interactivity (see the React/Web platform note for the exact classes).
- **Toggle size**: 14px chevron icon.
- **Toggle button padding**: `0.125rem` on all sides.
- **Toggle button corner radius**: platform-default rounded corner (`0.25rem` on web).
- **Toggle icon/text color**: muted-foreground token by default, default-foreground token on hover.
- **Toggle focus ring**: 2px ring in the accent (gold) token at 40% opacity, shown on focus-visible.
- **Toggle transition**: icon rotation is animated (see Accessibility Options → Reduce Motion).
- **Spacer size**: matches the toggle's box exactly (icon size + padding on all sides), so a leaf's content starts where a parent's does.
- **Layout**: flex row, items centered on the cross axis, with a small consistent gap between the toggle/spacer and the content.
- **Min-inline-size**: the label's outer element allows its inline size to shrink to zero so overflowing content can be truncated by the caller.

