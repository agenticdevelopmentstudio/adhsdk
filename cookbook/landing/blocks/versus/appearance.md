
- **Layout**: Two columns of equal width, arranged horizontally, when there's room for both; collapses to a single stacked column ("them" above "us") below a minimum column width of `18rem` (web implementation; a port states its own equivalent) — see **stack-below-breakpoint**.
- **Column spacing**: Gap between panels determined by platform design guidelines
- **Title styling**: h3 element; the web stylesheet sets it small (`0.72rem`), uppercase, letter-spaced, weight 400, dimmed for "them" and accent-coloured for "us". Ports use the platform heading style for titles and set no fixed weight; assumes Versus sits under a page section already at h2 or above — see **Accessibility**.
- **Lede styling**: Paragraph element with top margin, styled as introductory text
- **Points styling**: Unordered list with bullet markers, items as li elements
- **Visual distinction**: "us" panel receives highlighting (background, border, or accent color); "them" panel uses neutral styling
- **Padding**: Consistent padding within each panel
- **Background**: Platform-dependent; typically neutral for "them", accent or highlight for "us"

