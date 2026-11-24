
- **Corner radius**: Bars have rounded top corners; the tooltip is `rounded-md`; dots and legend swatches are round.
- **Padding**: Tooltip 6 × 10 pixels; table cells 4 × 8 pixels; the value-axis column is 40 pixels wide with an 8-pixel gap to the plot.
- **Font**: Monospace throughout. Tick and axis labels 10 pixels; tooltip, legend and table 11 pixels; empty label `text-xs`. Tooltip values are semibold.
- **Background**: Transparent plot. Tooltip uses the `apt-surface` token. Series colors come from the caller as CSS values.
- **Foreground/Text**: Ticks, axis labels and tooltip date in `apt-text-dim`; series names in `apt-text-muted`; tooltip values in `apt-text`.
- **Border**: Gridlines use the `apt-border` token, 1 pixel; the tooltip has a 1 pixel `apt-border`.
- **Shadow**: Tooltip uses `shadow-md`. Each dot has a 2-pixel ring in `--color-apt-surface` so it reads where it crosses another line.
- **Min/Max size**: Plot height is the `height` prop (default 200). Tooltip is at most 220 pixels wide. Bars are at most 24 pixels wide. The table region scrolls beyond 14rem (`max-h-56`). The legend and table are indented 48 pixels to align with the plot.

