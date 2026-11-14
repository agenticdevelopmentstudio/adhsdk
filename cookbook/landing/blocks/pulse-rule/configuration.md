
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `className` | string (prop, optional) | none | Appended after `lp-pulse-rule`; carries the caller's placement such as width and margins |
| `--lp-pulse-rule-period` | CSS time (custom property) | `6s` | Length of one breathing cycle; set on the element or an ancestor to slow the rule |
| `--lp-pulse-rule-floor` | CSS number (custom property) | `0.35` | Opacity at the low point of the cycle; set it higher to flatten the pulse, lower to deepen it |
| `--lp-accent` | CSS color (custom property) | `#9a9a9a` | Colour at the centre of the gradient; shared with the rest of the landing kit |

The host stylesheets `site-template/src/css/bridge.css` and `adh/src/styles/adh-landing-bridge.css` both set the period to `6s` and the floor to `0.35`.

