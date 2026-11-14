
- **Corner radius**: None
- **Padding**: Top and bottom padding, with dock clearance on the bottom, set directly by `.lp-site-foot` in `flow.css` — not inherited from `Wrap` or from descendants (values in **apply-footer-chrome**).
- **Font**: Set by `.lp-site-foot` itself; not inherited (size in **apply-footer-chrome**).
- **Background**: `var(--lp-ground, #101010)`, set by `.lp-site-foot` itself — the component does not leave background to its children.
- **Foreground/Text**: `var(--lp-ink-dim, #a0a0a0)`, set by `.lp-site-foot` itself. Descendant links override to `var(--lp-ink, #ededed)` via `.lp-site-foot a` (see **style-descendant-links**).
- **Border**: Top hairline in `var(--lp-hairline, rgba(255, 255, 255, 0.1))`, set by `.lp-site-foot` itself (width in **apply-footer-chrome**).
- **Shadow**: None applied by component
- **Min/Max size**: Full width; constrained content width via the `Wrap` component, which handles horizontal centering and max measure only — it does not contribute the padding, background, border, color, or font described above.

