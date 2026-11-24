
- **Container element**: `<div>`
- **Base class**: `lp-cards` — `lp-` is the fixed class-prefix namespace of `@adh-sdk/landing`, not a per-consumer template variable.
- **Variant classes**: `lp-cards--pair`, `lp-cards--trio`
- **Layout basis**: CSS Grid. Base track (no `pair`/`trio`): `grid-template-columns: repeat(auto-fit, minmax(16.5rem, 1fr))` (a 231px floor at this package's 87.5% root font size), with `gap: 1rem` (14px).
- **Default behavior**: The base auto-fit track above; no breakpoint applies.
- **Pair behavior**: `pair={true}` renders a single `minmax(0, 1fr)` column below a 48rem (768px) viewport width, and switches to an explicit two-column track (`repeat(2, minmax(0, 1fr))`) at 48rem and above.
- **Trio behavior**: `trio={true}` renders a single `minmax(0, 1fr)` column below a 56rem (896px) viewport width, and switches to an explicit three-column track (`repeat(3, minmax(0, 1fr))`) at 56rem and above.
- **Styling**: Controlled entirely through CSS classes; no inline styles applied by component

