
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | renders-label-and-value, tints-value-by-tone | `<StatRow label="uptime" value="99.9%" tone="success" />` | "uptime" and "99.9%" both present; value carries `text-apt-green` |
| T2 | defaults-neutral-tone, value-uses-figure-type | `<StatRow label="builds · 24h" value="12" />` | value "12" carries `text-apt-text` and the figure type `font-mono text-lg font-bold leading-none` |
| T3 | value-class-overrides-tone | `<StatRow label="env" value="PROD" tone="error" valueClassName="text-apt-blue" />` | value carries `text-apt-blue` and NOT `text-apt-red` |
| T4 | tints-value-by-tone, column-right-aligns | `<Stat label="failures · 24h" value="3" tone="error" />` | value "3" carries `text-apt-red`; label present; wrapper `flex-col items-end` |
| T5 | row-lays-out-on-baseline | `<StatRow label="x" value="1" />` | wrapper carries `items-baseline justify-between` |
| T6 | label-uses-micro-caption | `<Stat label="uptime" value="99.98%" />` | label span carries `text-[10px] uppercase tracking-[0.06em] text-apt-text-dim` |
| T7 | forwards-classname | `<StatRow className="pt-1" .../>` | wrapper carries `pt-1` |
| T8 | renders-label-and-value | `label={<b>N</b>} value={0}` | node label rendered; value `0` rendered (not dropped) |
| T9 | forwards-classname | `<Stat className="pb-2" label="x" value="1" />` | wrapper carries `pb-2` |

