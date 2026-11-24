
```
tone=success   ●  (apt-green fill + green glow halo)
tone=error     ●  (apt-red fill + red glow halo)
tone=accent    ●  (apt-gold fill + gold glow halo)

size=8   ·      size=12   ●      size=18   ⬤   (glow radius grows with size)
```

- Base: `inline-block shrink-0 rounded-full` — a shrink-proof inline circle that
  sits on the text baseline beside a label.
- Fill: `background: currentColor` (inline style), where `currentColor` comes
  from the tone's `text-apt-*` class.
- Glow: `boxShadow: 0 0 {glow}px color-mix(in srgb, currentColor 40%, transparent)`
  — a 40%-opacity halo of the same color, radius `max(6, round(size * 0.55))`.
- Size: inline `width` / `height` in px (default 10), so it aligns optically
  with adjacent mono text at any size.
- Fully token-driven (`apt-*` tones); no raw hex, no `!important`.

