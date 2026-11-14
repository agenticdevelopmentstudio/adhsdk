
- **Corner radius**: None; the rule is a flat 1px line.
- **Padding**: None; spacing is the caller's, supplied through `className`. The stylesheet sets no margin, so the browser's default `<hr>` margin applies unless the caller overrides it.
- **Font**: Not applicable: the element renders no text.
- **Background**: `linear-gradient(90deg, transparent, var(--lp-accent, #9a9a9a) 50%, transparent)`. The stylesheet comment explains the symmetry: a rule that starts solid and trails off has a left edge, and this one is drawn under centred type.
- **Foreground/Text**: Not applicable: the element renders no text.
- **Border**: `border: 0`, which removes the default `<hr>` border so the gradient is the only visible mark.
- **Shadow**: None.
- **Min/Max size**: Height is fixed at `1px`. Width is not set by the component; the caller sets it through `className`.
- **Motion**: `lp-pulse-rule-breathe`, `ease-in-out`, `infinite`. Opacity goes from `--lp-pulse-rule-floor` (default 0.35) at 0% to 1 at 50% and back to the floor at 100%. A full cycle takes `--lp-pulse-rule-period` (default 6s).

