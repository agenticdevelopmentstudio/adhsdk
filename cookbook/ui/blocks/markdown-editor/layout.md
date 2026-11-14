
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
- With `fill`, the root gains `min-h-0 flex-1` and the textarea flexes to fill it
  (no `rows`, no resize grip); the parent MUST provide a bounded height (see
  **fill-parent-height**).
- Tokens only (the `apt-*` token utilities, inherited from Textarea/Label/Button/Popover);
  no raw hex, no `!important`.

