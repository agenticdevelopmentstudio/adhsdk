
`StatRow` (dashboard-card form):

```
UPTIME                              99.98%   ← success tint
BUILDS · 24H                            12   ← neutral (default)
FAILURES · 24H                           0   ← muted
└ micro uppercase-mono label        └ big mono-bold value, right on the baseline
```

`Stat` (hero-strip form):

```
        99.98%     ← value on top, right-aligned, tinted
        UPTIME     ← micro label beneath
```

- Value: `statValueVariants` = `font-mono text-lg font-bold leading-none` + the tone
  color token; `valueClassName` merges after via `cn()`.
- Label: `font-mono text-[10px] uppercase tracking-[0.06em] text-apt-text-dim` — the
  display micro-caption, deliberately smaller/dimmer than the form-field caption.
- `StatRow` wrapper: `flex items-baseline justify-between gap-3`.
- `Stat` wrapper: `flex flex-col items-end gap-px` (`items-start` when `align="start"`).
- `StatStrip` wrapper: `flex flex-wrap gap-x-8 gap-y-3`.
- Color comes entirely from `apt-*` tokens; no raw hex, no `!important`.

