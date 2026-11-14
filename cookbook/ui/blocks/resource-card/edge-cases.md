
- **No props except title**: Card renders as inert div with title only. No errors occur.
- **Very long title**: Title text wraps to multiple lines within the card width. No truncation.
- **Very long identifier**: Identifier may wrap; recommend limiting identifier length in parent or using text-overflow/ellipsis in custom styling.
- **Description exceeds 3 lines**: Description is clamped to 3 lines via line-clamp-3; overflow text is hidden.
- **Meta content overflows horizontally**: Meta row uses flex-wrap to wrap items to the next line with gap-y-1 (0.25rem) between rows.
- **Both href and onClick with navigation**: onClick runs synchronously and is never awaited, so the anchor's navigation is not delayed by it — see **href-precedence**. `onClick` is typed `() => void`, so the card hands the host's handler no event and itself never calls `preventDefault` on the anchor click.
- **Empty href**: `href=""` is not `undefined`, so the card still renders through `LinkComponent` as a link with an empty destination.
- **Falsy numeric content**: `identifier`, `description` and `meta` are guarded with `&&`, so `0` renders the text "0"; `false`, `null`, `undefined` and `""` render nothing. See resource-card-021 to resource-card-023 and the caller rules in **optional-identifier**, **optional-description** and **optional-meta**.
- **Empty or null meta children**: If `meta` is present but contains no children, an empty flex row is rendered; no content or error. Callers should omit `meta` entirely rather than pass an empty node, to avoid the unwanted gap.
- **Interactive content in `meta` on an interactive card**: See **meta-no-nested-interactive**. Nesting a link or button inside an anchor or `role="button"` container is invalid HTML and unreachable by assistive technology; restrict `meta` to static chips (text, icons) when the card itself is interactive.

