
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | renders-progressbar-role, fixed-value-bounds | UI: render `<Progress value={35} />` | element has `role="progressbar"`, `aria-valuemin="0"`, `aria-valuemax="100"` |
| T2 | reflects-value-in-valuenow, fill-tracks-value | UI: `value={35}` | `aria-valuenow="35"`; indicator transform `translateX(-65%)` |
| T3 | defaults-to-zero | UI: render `<Progress />` (no `value`) | `aria-valuenow="0"`; indicator transform `translateX(-100%)` |
| T4 | clamps-below-zero | UI: `value={-40}` | `aria-valuenow="0"`; transform `translateX(-100%)` |
| T5 | clamps-above-hundred | UI: `value={140}` | `aria-valuenow="100"`; transform `translateX(-0%)` |
| T6 | reflects-value-in-valuenow | UI: `value={35.6}` | `aria-valuenow="36"` (rounded) |
| T7 | indicator-class-tints-fill | UI: `value={100} indicatorClassName="bg-apt-green"` | fill element carries `bg-apt-green` and NOT `bg-apt-gold` (`cn()` runs `tailwind-merge`, which drops the conflicting `bg-*` utility) |
| T8 | forwards-track-props, requires-accessible-name | UI: `aria-label="Sync" id="p1"` | track element carries `aria-label="Sync"` and `id="p1"` |
| T9 | honors-shared-reduce-motion | UI: render `<Progress value={35} />` under `html[data-reduce-motion="on"]` | computed `transition-duration` on the indicator resolves to `0.001ms` (the shared `accessibility.css` override), superseding the nominal `calc(300ms*var(--apt-anim-scale,1))` duration |
| T10 | clamps-below-zero, clamps-above-hundred (see **non-finite-value-handling** under Edge Cases) | UI: `value={NaN}` | `aria-valuenow="NaN"`; transform `translateX(-NaN%)` — `Math.min`/`Math.max` return `NaN` when either operand is `NaN`, so this one non-finite value passes through unclamped |
| T11 | pairs-tint-with-text-status | UI: `value={100} indicatorClassName="bg-apt-green" aria-valuetext="Complete"` | fill element carries `bg-apt-green`; track element carries `aria-valuetext="Complete"`, conveying the status alongside the color tint rather than through color alone |
| T12 | clamps-above-hundred (see **non-finite-value-handling** under Edge Cases) | UI: `value={Infinity}` | `aria-valuenow="100"`; transform `translateX(-0%)` — identical to T5; `Math.min`/`Math.max` treat `Infinity` as an ordinary large number |
| T13 | clamps-below-zero (see **non-finite-value-handling** under Edge Cases) | UI: `value={-Infinity}` | `aria-valuenow="0"`; transform `translateX(-100%)` — identical to T4 |
| T14 | accepts-label, accepts-hint | Controls: `<Progress label="Sync" hint="Uploading" value={40} />` | wrapper renders an `aws-field__label` reading "Sync" and an `aws-field__hint` reading "Uploading"; progressbar has `aria-valuenow="40"` |
| T15 | valuemin-fixed-valuemax-configurable | Controls: `<Progress value={5} max={10} />` | `aria-valuemin="0"`, `aria-valuemax="10"`; fill width `50%` |
| T16 | reports-raw-valuenow, clamps-fill-width-only | Controls: `<Progress value={-40} />` | `aria-valuenow="-40"` (not clamped); fill width `0%` (width clamped to the 0–100% range) |
| T17 | reports-raw-valuenow, clamps-fill-width-only | Controls: `<Progress value={140} max={100} />` | `aria-valuenow="140"` (not clamped); fill width `100%` (width clamped) |
| T18 | reports-raw-valuenow | Controls: `<Progress value={35.6} />` | `aria-valuenow="35.6"` (not rounded, unlike the UI bar's T6) |
| T19 | omits-valuenow-without-value | Controls: render `<Progress />` (no `value`) | `aria-valuenow` is omitted entirely (unlike the UI bar's T3, which defaults to `"0"`); fill width `0%` |
| T20 | indeterminate-mode | Controls: `<Progress indeterminate />` | wrapper carries `aws-field--progress-indeterminate`; `aria-valuenow` omitted; fill element has no inline `width` style |

