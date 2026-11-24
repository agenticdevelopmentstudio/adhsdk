
Filter field, then either the tree or the filtered list, then the button bar:

```
┌───────────────────────────────────────────┐
│ Move "Q3"                                  │  ← title — the host's own words
│ Choose where it should sit. Its other      │  ← optional description
│ filings are left alone.                    │
├───────────────────────────────────────────┤
│ [ Filter categories…                    ]  │  ← Input, autoFocus, role="searchbox"
├───────────────────────────────────────────┤
│   Top level                                │  ← allowRoot row (FolderTree icon, no chevron)
│ ▾ Work                                     │  ← expanded parent (ChevronDown)
│     Q1                                     │  ← child of Work (Folder icon, no chevron)
│     Q2                                     │
│ ▸ Planning                                 │  ← collapsed parent (ChevronRight)
├───────────────────────────────────────────┤
│                         Cancel      Move   │  ← DialogActions; confirm disabled if unpickable
└───────────────────────────────────────────┘
```

Filtering ("q" typed) replaces the tree with a flat `listbox` of matches, each
row showing the match name and its dim, monospace ancestor trail underneath.
Selected row: `bg-apt-gold/15`. Disabled row: `opacity-40`. All color from
`apt-*` tokens; no raw hex, no `!important`.

