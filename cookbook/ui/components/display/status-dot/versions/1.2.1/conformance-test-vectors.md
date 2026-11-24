
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | unlabeled-is-decorative, derives-fill-from-currentcolor | render `<StatusDot tone="success" />` | span has `aria-hidden="true"`; inline `background` is `currentcolor` |
| T2 | labeled-is-accessible-image, tone-sets-currentcolor | `<StatusDot tone="error" size={20} label="down" />` | element found by `role="img"` name `down`; className contains `text-apt-red` |
| T3 | scales-glow-with-size, derives-glow-from-currentcolor | `size={20}` | inline `boxShadow` contains `11px` (round(20 × 0.55)) and a `color-mix` of `currentColor` |
| T4 | labeled-is-accessible-image | `label="down"` | no element matches `[aria-hidden="true"]` |
| T5 | scales-glow-with-size | `size={8}` | glow radius clamps to `6px` (max(6, round(8 × 0.55)=4)) |
| T6 | defaults-to-neutral-tone | render `<StatusDot />` (no tone) | className contains `text-apt-text-muted` |
| T7 | sizes-in-px | `size={18}` | inline `width` and `height` are `18px` |
| T8 | merges-classname | `className="ml-1"` | className contains both `ml-1` and the tone class |
| T9 | tone-sets-currentcolor | render `<StatusDot tone="muted" />` | className contains `text-apt-text-dim` |
| T10 | tone-sets-currentcolor | render `<StatusDot tone="accent" />` | className contains `text-apt-gold` |
| T11 | tone-sets-currentcolor | render `<StatusDot tone="blue" />` | className contains `text-apt-blue` |
| T12 | tone-sets-currentcolor | render `<StatusDot tone="orange" />` | className contains `text-apt-orange` |
| T13 | unlabeled-is-decorative, passes-label-through-verbatim | `<StatusDot tone="success" label="" />` | span has `aria-hidden="true"` and no `role` attribute (empty string is falsy) |
| T14 | scales-glow-with-size | `size={10}` | inline `boxShadow` contains `6px` (round(10 × 0.55) = 6, exactly at the floor) |

