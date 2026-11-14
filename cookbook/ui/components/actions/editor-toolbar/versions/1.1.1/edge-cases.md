
- **No children**: Component MUST render successfully with `children={undefined}` or `children={[]}`, producing an empty `<div role="toolbar">` element.
- **Single child**: Component MUST render successfully with a single child; gap spacing is not visible with only one child.
- **Empty ariaLabel**: If `ariaLabel=""` is explicitly passed, component MUST apply the empty string as the aria-label as given — it does not fall back to the default and does not warn. Assistive technology then announces only the role ("toolbar") with no accessible name; callers must not pass an empty string if they want the region to have an accessible name.
- **Multiple className values with conflicting styles**: The `cn()` utility resolves class conflicts using `tailwind-merge`, which is deterministic: within the same Tailwind class group, the later class in the merged argument order wins. A caller's `gap-4` therefore overrides the default `gap-1.5` (see Conformance Test Vector editor-toolbar-011).
- **Server-side rendering**: Component is server-safe; it contains no hooks or client-side logic and MUST render correctly in server-side rendering contexts.

