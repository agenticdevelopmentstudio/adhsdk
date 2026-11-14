
- **Corner radius**: None
- **Padding**: `clamp(3rem, 6vw, 5rem)` top; the same clamp value plus `var(--lp-dock-clear, 0px)` on the bottom. Set directly by `.lp-site-foot` in `flow.css` — not inherited from `Wrap` or from descendants (see **apply-footer-chrome**).
- **Font**: `0.86rem`, set by `.lp-site-foot` itself; not inherited.
- **Background**: `var(--lp-ground, #101010)`, set by `.lp-site-foot` itself — the component does not leave background to its children.
- **Foreground/Text**: `var(--lp-ink-dim, #a0a0a0)`, set by `.lp-site-foot` itself. Descendant links override to `var(--lp-ink, #ededed)` via `.lp-site-foot a` (see **style-descendant-links**).
- **Border**: `1px solid var(--lp-hairline, rgba(255, 255, 255, 0.1))` top hairline, set by `.lp-site-foot` itself.
- **Shadow**: None applied by component
- **Min/Max size**: Full width; constrained content width via the `Wrap` component, which handles horizontal centering and max measure only — it does not contribute the padding, background, border, color, or font described above.

