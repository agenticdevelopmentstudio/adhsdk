
```
┌ InfoPanel  aria-label = title ─────────────────────────────┐
│ [icon] Title                              PostHog ↗         │  header (icon + title; link in actions)
├────────────────────────────────────────────────────────────┤
│ ┌ body stack: flex flex-col gap-2.5 ────────────────────┐   │
│ │ PAGEVIEWS · 7D                                637      │   │  ← StatRow (stats[0])
│ │ VISITORS · 7D                                 538      │   │  ← StatRow (stats[1])
│ │ …children (freeform, after the rows)…                 │   │
│ │ anonymous · cookieless · approximate                  │   │  ← footnote (muted mono 10px)
│ └───────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────┘
```

- Shell: `InfoPanel` in its default content-sized (non-scroll) mode; `title`, `icon`,
  `className`, and remaining host attributes pass straight through; the InfoPanel
  actions slot receives the `ExternalLink` (when `link` is set) followed by any
  extra `actions`, and is omitted when both are absent.
- Body: a single `<div className="flex flex-col gap-2.5">` holding, in order, the
  mapped `StatRow`s, then `children`, then the footnote.
- Footnote: `pt-0.5 font-mono text-[10px] text-apt-text-dim` — matched to the StatRow
  label's micro-caption grammar; rendered only when `footnote != null`.
- No raw hex, no `!important` — all color/typography via `apt-*` tokens and the
  composed shared parts.

