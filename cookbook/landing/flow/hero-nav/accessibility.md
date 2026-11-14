
- **role**: The `nav` element exposes the navigation landmark; each row is a native link.
- **label**: The `nav` takes its accessible name from the required `label` prop, which the doc comment says is the host's copy.
- **separators**: Separators are `aria-hidden="true"`, so assistive technology reads only the links.
- **keyboard**: Links are native anchors, reachable by Tab and activated by Enter with no script.
- **focus-visible**: A 2px accent outline with a 3px offset shows on `:focus-visible`.
- **reduced-motion**: The lens sweep is skipped when `prefers-reduced-motion: reduce` matches, by the lens's default of respecting it.
- **contrast**: NEEDS REVIEW: Not implemented in source. The links are `--lp-ink-dim` text at 0.8rem, and neither this source nor `flow.css` states a contrast ratio for that token against the page background; a contrast check of the host's token values would settle it.
- **target-size**: NEEDS REVIEW: Not implemented in source. A link's height is its 0.8rem text plus 8px of padding above and below, with no width or height floor, and the source cannot decide whether that meets the 44×44pt Apple HIG or 24×24 CSS px WCAG 2.2 target size; measuring the rendered links would settle it.

