
```
┌ trigger ─────────┐
│ [▮] Markdown     │  ← outline Button (size sm), BookText icon + label
└──────────────────┘
        ▼ on open (popover, side=bottom align=end, w-80)
  ┌──────────────────────────────────────┐
  │ MARKDOWN QUICK REFERENCE              │  ← mono uppercase caption
  │ Headings     # H1 / ## H2 / ### H3    │  ← <dl>: term | <code> snippet
  │ Bold         **bold text**            │
  │ Italic       _italic text_            │
  │ Inline code  `inline code`            │
  │ Code block   ```ts … ```              │
  │ Bullet list  - one / - two            │
  │ Numbered list 1. one / 2. two         │
  │ Link         [label](https://url)     │
  │ Blockquote   > quoted text            │
  └──────────────────────────────────────┘
```

- Trigger: shared `Button` via `buttonVariants({ variant: "outline", size: "sm" })`
  with a leading `BookText` icon (`data-icon="inline-start"`).
- Popover surface: the shared `PopoverContent` (`bg-apt-surface`,
  `border-apt-border`, `text-apt-text`), widened to `w-80`.
- Caption: the shared `fieldCaptionClass` (from `lib/typography`), not a
  hard-coded style — this is what keeps the caption typography from forking
  between `SyntaxQuickReference` consumers.
- Rows: a two-column `<dl>` with the column widths set by `columnsClassName`
  (default `grid-cols-[7rem_1fr]`) — `<dt>` label in `text-apt-text-muted`,
  `<dd>` a `whitespace-pre-wrap` mono `<code>` in `text-apt-text`.
- Tokens only: no raw hex, no arbitrary colors, no `!important`.

