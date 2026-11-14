
- **Layout**: Flex container (`flex items-start justify-between gap-4`). The left section (title/eyebrow) has no flex-shrink override, so by default it may shrink and its content may wrap; the right section (actions/help) is `shrink-0` and never shrinks, so actions and the help trigger are never compressed.
- **Left section spacing**: Vertical stack with `space-y-1` between eyebrow and title.
- **Eyebrow font**: Monospace, 0.65rem (10.4px), uppercase, tracking-wider, color uses `apt-text-dim` semantic token.
- **Title font**: Monospace, text-sm (14px), font-medium (500 weight), tracking-wide, color uses `apt-gold` semantic token.
- **Help button**: Uses `quietControlClass` for muted styling; icon is 16×16px CircleHelp (lucide-react).
- **Help popover**: Width of 288px (`w-72`), capped at the available width by the Popover's `max-w-(--available-width)`, positioned at `bottom` and aligned to `end` (right edge).
- **Hoisted title**: When hoisted, the pane holds no h2; the title is drawn by the detail strip's own title cell, with its styling.
- **Right section spacing**: Flex with `gap-2` between actions and help button; `shrink-0` prevents flex shrinking.

