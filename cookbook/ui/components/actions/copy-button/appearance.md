
```
idle       [ ⧉ ]   outline square, muted clipboard glyph        title = label
success    [ ✓ ]   apt-green check, title "Copied!"  (1200 ms)  then reverts
```

- Chrome: the shared `Button` with `variant="outline"` and `size="icon"`, overridden
  down to `size-6` (a 24px square) via `className` so it sits inline beside text or a
  label without dominating.
- Idle glyph: the lucide `Copy` icon, tinted `text-apt-text-muted`.
- Success glyph: the lucide `Check` icon, tinted `text-apt-green`.
- Colors are token-based (`apt-text-muted`, `apt-green`) and merge through `cn()`; no
  raw hex, no `!important`.

