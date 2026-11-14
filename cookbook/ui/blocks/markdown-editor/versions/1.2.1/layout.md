
```
┌ MarkdownEditor (flex flex-col gap-1.5) ────────────────────────────┐
│ ┌ header row (flex items-center justify-between) ────────────────┐ │
│ │ MARKDOWN BODY            [extras] [⬆ Upload .md] [▮ Markdown]   │ │
│ │  └ Label (htmlFor)        └──── EditorToolbar (role="toolbar") ─┘ │
│ └────────────────────────────────────────────────────────────────┘ │
│ ┌ Textarea (id, rows, mono) ─────────────────────────────────────┐ │
│ │ # My research                                                  │ │
│ │ …                                                              │ │
│ └────────────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────────┘
```

- The header row puts the `Label` on the left and the `EditorToolbar` on the
  right (`justify-between`).
- Toolbar order: `toolbarExtras` → Upload .md (if `onUpload`) → quick reference
  (if `quickReference`).
- The textarea sits full-width below the row, mono (`font-mono text-[0.8rem]`),
  `rows` tall (default 16).
- Tokens only (inherited from Textarea/Label/Button/Popover); no raw hex, no
  `!important`.

