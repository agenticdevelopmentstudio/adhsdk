
- **Corner radius**: `min(var(--radius-md), 12px)` — contributed by the icon-sm size variant, not the ghost variant (ghost adds no radius override; the base button class's `rounded-lg` is overridden by icon-sm's radius utility).
- **Padding**: Gap between buttons is 0.5 (2px in Tailwind spacing scale — `gap-0.5` = 0.125rem).
- **Font**: Inherited from Button component (not directly styled)
- **Background**: Transparent (ghost variant)
- **Foreground/Text**: text-apt-text-muted (muted color applied to icons)
- **Border**: None (ghost variant)
- **Shadow**: None
- **Min/Max size**: 28×28px, fixed by the icon-sm Button variant's `size-7` utility.

