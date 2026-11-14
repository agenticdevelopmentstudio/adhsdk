
```
┌ ButtonBar (role=toolbar) ───────────────────────────────────────────────┐
│ ⬤ title  [titleBadge]      + New │ 🗑 Delete … ✕ Cancel   ✓ Save          │
├──────────────────────────────────────────────────────────────────────────┤
│ error (red line, only when `error` set)                                   │
├──────────────┬───────────────────────────────────────────────────────────┤
│ rail (TopicDetail, collapsible)  │  detail pane                           │
│  [listHeader]                    │                                        │
│  ▸ record label       ⚠         │   editing → children (record form)     │
│    sublabel                      │                                        │
│  ▸ record label       ⚠ 5       │   not editing → EmptyState(emptyDetail) │
│  ▸ record label                  │                                        │
│  (empty → emptyList)             │                                        │
└──────────────┴───────────────────────────────────────────────────────────┘
```

- Root is a full-height column that fills its container edge-to-edge (rail/pane
  stretch to it); give the parent a height. (Literal classes: see the React/Web
  platform note.)
- Toolbar: the `ButtonBar` recessed strip; title uses the small monospace gold
  title treatment, with the optional `titleBadge` beside it. (Literal classes:
  see the React/Web platform note.)
- Error line: a non-shrinking bordered strip in small monospace red text, only
  present when `error` is set. (Literal classes: see the React/Web platform
  note.)
- Rail + pane come from `TopicDetail` with `panePadding={false}` (each row/pane
  supplies its own inset); rail width defaults to the standard rail and widens via
  `railWidth` for long identifier rows.
- The pane's `EmptyState` uses a fixed standard inset (a small margin plus a
  minimum height) rather than filling the pane exactly. (Literal classes: see
  the React/Web platform note.)
- No raw hex; no `!important` (all color via `apt-*` tokens).

