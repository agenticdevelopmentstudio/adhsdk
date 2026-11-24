
- **Background**: Secondary surface color token (Material 3 `surface-container-high` role, injected at runtime by the active theme)
- **Corner radius**: Medium — 0.8× the design system's base radius token (0.4rem / 6.4px with this repo's default `--radius: 0.5rem`)
- **Animation**: Continuous pulsing opacity animation — 2s duration, `cubic-bezier(0.4, 0, 0.6, 1)` easing, opacity cycles 1 → 0.5 → 1, infinite (Tailwind's default `pulse` keyframe, unmodified by this design system)
- **Padding**: None — the element is block-level with no padding
- **Border**: None
- **Shadow**: None
- **Min/Max size**: None (sized by the consumer via `className` or inline styles)

