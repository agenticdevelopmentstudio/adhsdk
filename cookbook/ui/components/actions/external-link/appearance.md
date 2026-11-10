
```
default            PostHog ↗          (mono · text-[11px] · apt-blue · trailing arrow)
glyph={false}      ⤴ GitHub           (leading lucide icon; no trailing arrow; restyled)
```

- Base: `inline-flex items-center gap-1 rounded-sm font-mono text-[11px]
  whitespace-nowrap text-apt-blue no-underline outline-none
  focus-visible:ring-2 focus-visible:ring-apt-gold/40`.
- Trailing glyph: a `<span aria-hidden="true">↗</span>` rendered only when
  `glyph` is truthy (default).
- Restyle path: `className` is `cn()`-merged last, so a consumer can override
  font (`font-sans`), size, color, and gap — e.g. UserCard's social links use
  `gap-1.5 font-sans text-sm text-apt-text-muted hover:text-apt-text`.
- Token-driven color (`apt-blue`, `apt-gold`); no raw hex, no `!important`.

