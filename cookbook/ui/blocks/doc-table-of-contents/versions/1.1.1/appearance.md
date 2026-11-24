
- **Corner radius**: None; component uses only sharp edges.
- **Padding**: Vertical 2 rem (8 units) × horizontal 1 rem (4 units) on the container; individual headings use vertical 0.125 rem (0.5 units) and horizontal padding based on depth (0.75 rem / 3 units, or 1.5 rem / 6 units for depth-3 headings).
- **Font**: Title uses monospace, 10px, medium weight, uppercase. Headings use sans-serif, small size (14px), regular weight (inactive) or medium weight (active).
- **Background**: Transparent; no background color is applied.
- **Foreground/Text**: Title uses `--color-text-dim`. Inactive headings use `--color-text-dim` with hover state to `--color-text-secondary`. Active heading uses `--color-text-primary` and font-medium.
- **Border**: Left border on the heading list uses `--color-border-subtle` (1px width). Individual headings have a left border that is 1px wide and is transparent (inactive) or uses `--color-accent` (active).
- **Shadow**: None.
- **Min/Max size**: Fixed width 14 rem; does not grow or shrink. Height is viewport height minus header height with overflow-y-auto scrolling.

