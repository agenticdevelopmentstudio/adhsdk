
```
┌──────────────────────────────────────────────┐
│  [avatar]  Display Name                      │
│            @slug                             │
│            MEMBER SINCE <Month Year>         │
├──────────────────────────────────────────────┤  ← the only divider (only when gated content)
│  SOCIAL                                      │
│  ↗ Platform @handle   ↗ Platform @handle     │  ← wrapping flex row
│  EMAIL                                       │
│  ✉ email@example.com                         │
│  PHONE / ADDRESS / PERSONAS …               │
└──────────────────────────────────────────────┘
```

- Root: rounded corners, a 1px border in the border color, the page background, and primary text color.
- Avatar: 64px on small screens, 80px from the small breakpoint up, with a fallback initials ring.
- Display name: serif, 24px on small screens, 30px from the small breakpoint up.
- Slug: monospace, 14px, muted text color.
- Member since: monospace, small uppercase text with wide letter spacing, dim text color.
- Section labels: monospace, extra-small uppercase text with wide letter spacing, dim text color.
- Social links: inline flex, muted text color that becomes primary text color on hover, and a focus ring in the accent color at 40% opacity.
- Persona items: rounded, bordered, on the raised surface color, with a badge for `visibility`.

The React/Web classes behind these roles are listed in Platform Notes.
