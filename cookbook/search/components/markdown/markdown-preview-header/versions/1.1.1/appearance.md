
- **Layout**: Vertical stack with 8pt gap between sections (title row, metadata row, summary, per-kind extra).
- **Title row**: Horizontal stack, space-between alignment, 12pt gap; the title is allowed to shrink below its content width (`min-w-0`), but nothing on the heading or its ancestors sets `truncate`, `overflow-hidden`, `text-overflow`, `white-space: nowrap`, or a line-clamp, so a title that exceeds the available width wraps onto additional lines instead of eliding with an ellipsis.
- **Title text**: Small text size, semibold weight, primary text color.
- **Metadata row**: Horizontal stack that wraps, 8pt horizontal / 4pt vertical gap, small text size, dimmed secondary text color. Contains the kind badge, author attribution, then the optional update date, in that fixed order (see **metadata-row-order**).
- **Author text**: Regular weight; the author value itself uses a muted text color.
- **Summary**: Small text, muted text color; the "Summary:" label is medium weight in a dimmed secondary color (see **summary-label**).
- **Public link**: Small text, medium weight, accent color, underlines on hover, no visible default outline, and shows a focus ring in the accent color at 40% opacity with an offset underline when focused via keyboard.
- **Link hit target**: Inline-flex, minimum height of 24pt (6 spacing units), does not shrink within its row, center-aligned content, small corner radius.

Concrete Tailwind classes and `apt-*` design tokens for this layout are given in **Platform Notes → Source (TypeScript/Web)**.

