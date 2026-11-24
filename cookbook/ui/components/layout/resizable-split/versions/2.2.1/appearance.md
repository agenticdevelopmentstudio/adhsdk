
```
seam (default):
┌───────────────────────────────┐
│  top                          │  flex: 0 1 ratio%
├────────── ▬▬ ──────────── ⌄ ──┤  1px seam + centered grip pill + 24px grab band
│  bottom                       │  flex: 1
└───────────────────────────────┘
header bar:
┌───────────────────────────────┐
│  top                          │  flex: 0 1 ratio%
├ Details ────────── [actions] ⌄┤  the bar IS the divider (drag anywhere on it)
│  bottom                       │  flex: 1
└───────────────────────────────┘
collapsed (either form):
┌───────────────────────────────┐
│  top (fills)                  │
├ Details ─────────────────── ⌃ ┤  only the divider/bar remains; bottom stays
└───────────────────────────────┘  mounted at height 0 (clipped, inert)
```

- **Container**: `flex flex-col min-h-0`. Panes: `min-h-0 overflow-auto` (bottom wrapped in `overflow-hidden` so the collapse animation never exposes a scrollbar).
- **Seam**: 1px `bg-apt-border`, hover `bg-apt-border-strong`; centered grip pill (`bg-apt-border-strong`, `rounded-full`, 10px × 4px); invisible 24px grab band centered on seam carries the drag; `cursor: row-resize`; chevron right-aligned, `text-apt-text-muted` on idle, `text-apt-text` on hover.
- **Header bar**: `border-y border-apt-border bg-apt-surface`, mono muted title left (`font-mono text-[11px] tracking-wide text-apt-text-muted`), actions + chevron right; `cursor: row-resize` across the bar (default cursor on its controls and while collapsed).
- **No raw hex**; no `!important`.

