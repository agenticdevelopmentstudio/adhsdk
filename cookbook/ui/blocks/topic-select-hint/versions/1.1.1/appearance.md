
- **Container**: Flex column, full height and width, centered items, overflow-y auto, 24px padding (p-6)
- **Card**: Maximum width 448px (max-w-md), gap 12px (gap-3), padding 32px horizontal × 40px vertical (px-8 py-10), centered text alignment
- **Icon circle**: 44px (size-11), flexbox centered, rounded full, border 1px (border-apt-border), background apt-surface, text color apt-text-dim
- **Icon**: 20px (size-5) MousePointerClick from lucide-react
- **Headline**: Font weight semibold, line height snug, text color apt-text
- **Description text**: Font size 14px (text-sm), line height relaxed, text color apt-text-muted; strong elements are semibold with apt-text color

**Design tokens** — the `apt-*` classes are semantic tokens the host project's Tailwind config must define; each maps to a platform-neutral color role a Swift, Compose, or WinUI port can use its own equivalent for:
- `apt-border`: neutral border/divider color (icon circle outline)
- `apt-surface`: elevated surface background (icon circle fill)
- `apt-text`: primary foreground text (headline, description `<strong>` runs)
- `apt-text-dim`: secondary/dim foreground (the decorative icon)
- `apt-text-muted`: tertiary muted foreground (description body text)

