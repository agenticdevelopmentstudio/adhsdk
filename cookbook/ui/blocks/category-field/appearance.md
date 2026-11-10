
- **Container**: Vertical flex layout (`flex-col`) with 0.5rem gap (`gap-2`) between combobox/chooser row and breadcrumbs.
- **Breadcrumb row**: Horizontal flex layout, wrappable with `flex-wrap`, `items-center`, 0.25rem horizontal gap (`gap-x-1`), 0.125rem vertical gap (`gap-y-0.5`).
- **List items**: Flex row with 0.25rem gap (`gap-1`), `items-center`, `min-w-0` to allow truncation.
- **Chevrons**: 12px size, `shrink-0` (no flex), `text-apt-text-dim` color.
- **Breadcrumb text**: Font monospace, 12px size (`text-xs`), 2% letter spacing (`tracking-[0.02em]`), truncated.
- **Parent breadcrumbs**: `text-apt-text-muted` color.
- **Leaf breadcrumbs**: `text-apt-gold` color.
- **Rename button**: Rounded (`rounded`), monospace font, 12px, 2% letter spacing, no outline, hover brightens to `text-apt-text`, focus shows 2px ring of `apt-gold` at 40% opacity.
- **Input row**: Horizontal flex, `items-stretch`, 0.5rem gap.
- **Combobox wrapper**: `flex-1` to expand.
- **Entity chooser**: `w-44 shrink-0` (fixed width, no flex shrinking).
- **Field wrapper**: Passes through `layout` prop ("stacked" or "inline") for label positioning.

