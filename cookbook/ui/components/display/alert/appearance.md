
- **Corner radius**: `rounded-lg` (design-token corner radius; exact px
  value comes from the project's Tailwind theme, which is not part of this
  source file).
- **Padding**: `py-3 px-4` — 0.75rem vertical × 1rem horizontal.
- **Font**: Alert body text `text-sm` (0.875rem); `AlertTitle` adds
  `font-medium`; `AlertDescription` is also `text-sm`.
- **Background**: variant-dependent — `bg-apt-surface` (default),
  `bg-apt-blue/10` (info), `bg-apt-green/10` (success), `bg-apt-red/10`
  (error), `bg-apt-gold/10` (accent). Resolved colors are defined by the
  `apt-*` design tokens, not by this source file.
- **Foreground/Text**: `text-apt-text` for every variant (the text color
  class does not change per variant); `AlertDescription` specifically uses
  `text-apt-text-muted`. The icon color does vary per variant (see Border,
  below).
- **Border**: `border` (1px, Tailwind's default border width), color
  variant-dependent — `border-apt-border` (default), `border-apt-blue/40`
  (info), `border-apt-green/40` (success), `border-apt-red/40` (error),
  `border-apt-gold/40` (accent). The same color token also tints the
  variant's icon (`[&>svg]:text-apt-*`), except `default`, whose icon uses
  `text-apt-text-muted` instead of a status color.
- **Shadow**: None. No `shadow-*` class appears in `alertVariants`.
- **Min/Max size**: `w-full` (100% of container width); no explicit
  min/max height or width beyond that.
- **Layout**: `grid`, `items-start`, `gap-y-0.5` (0.125rem) between grid
  rows; `grid-cols-[0_1fr]` by default, widening to
  `grid-cols-[1.25rem_1fr]` with `gap-x-3` (0.75rem) when a direct `<svg>`
  child is present (`has-[>svg]:...`).

