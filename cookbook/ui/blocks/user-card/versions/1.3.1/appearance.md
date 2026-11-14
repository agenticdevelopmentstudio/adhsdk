
```
┌──────────────────────────────────────────────┐
│  [avatar]  Display Name                      │
│            @slug                             │
│            MEMBER SINCE <Month Year>         │
├──────────────────────────────────────────────┤  ← separator (only when gated content)
│  SOCIAL                                      │
│  ↗ Platform @handle   ↗ Platform @handle     │  ← wrapping flex row
├──────────────────────────────────────────────┤
│  EMAIL                                       │
│  ✉ email@example.com                         │
├──────────────────────────────────────────────┤
│  PHONE / ADDRESS / PERSONAS …               │
└──────────────────────────────────────────────┘
```

- Root: `rounded-xl border border-apt-border bg-apt-bg text-apt-text`.
- Avatar: `size-16` mobile, `size-20` sm+, with a fallback initials ring.
- Display name: `font-serif text-2xl` mobile, `text-3xl` sm+.
- Slug: `font-mono text-sm text-apt-text-muted`.
- Member since: `font-mono text-[0.7rem] uppercase tracking-[0.08em] text-apt-text-dim`.
- Section labels: `font-mono text-[0.6rem] uppercase tracking-[0.1em] text-apt-text-dim`.
- Social links: inline flex, `text-apt-text-muted hover:text-apt-text`, focus ring `apt-gold/40`.
- Persona items: `rounded-lg border border-apt-border bg-apt-surface p-3`; badge for `visibility`.

