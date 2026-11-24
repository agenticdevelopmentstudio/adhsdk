
- **Desktop layout**: Sticky aside, positioned at `top: var(--adh-header-height, 3.5rem)`, width `24rem` (expanded to `32rem` at the `xl` breakpoint; shown from the `lg` breakpoint up, hidden below it), right-aligned border, vertical overflow scrolls independently of the viewport
- **Mobile layout**: Below the `lg` breakpoint the desktop aside is hidden and the nav is reached through a slide-over drawer (the drawer can also be opened at `lg` and above). Slide-over drawer positioned at `left: 0`, width `18rem`, appearing on top of a scrim at 50% opacity black
- **Section labels**: Mono font, extra-small size, medium weight, uppercase, wide letter-spacing, always colored `var(--color-accent)` (no hover color change)
- **Branch and leaf links**: Small text size for branches/leaves, extra-small for headings; secondary text color by default, primary on hover; selected/ancestor links use semibold or medium weight
- **Selected indicator**: Vertical accent bar (1px width, `var(--color-accent)` color) at left edge of selected link
- **Indentation**: Links and headings use consistent padding-inline-start (0.875rem); nested lists add 0.875rem left margin per level
- **Dividers**: Border-top line (1px, `var(--color-border-subtle)` above fixed rows, `var(--color-border)` within tree levels)
- **No text wrapping (desktop)**: Desktop nav prevents entries from wrapping onto a second line, with horizontal scrolling available for anything still too long; mobile allows wrapping

