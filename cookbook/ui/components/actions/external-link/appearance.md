
```
default            PostHog ↗          (mono · small · apt-blue · trailing arrow)
glyph={false}      ⤴ GitHub           (leading lucide icon; no trailing arrow; restyled)
```

- Base: inline layout with the items centered and a small gap, a small
  rounded corner, a small monospace size, no wrapping, the info-blue token
  color, no underline, and a keyboard-only focus ring in the accent token
  color. The literal web class list is in the React/Web Platform Note.
- Trailing glyph: a `<span aria-hidden="true">↗</span>` rendered only when
  `glyph` is truthy (default), mirrored horizontally under a right-to-left
  layout (**mirrors-glyph-rtl**).
- Restyle path: `className` is `cn()`-merged last, so a consumer can override
  font (`font-sans`), size, color, and gap — e.g. UserCard's social links use
  `gap-1.5 font-sans text-sm text-apt-text-muted hover:text-apt-text`.
- Token-driven color (`apt-blue`, `apt-gold`); no raw hex, no `!important`.

