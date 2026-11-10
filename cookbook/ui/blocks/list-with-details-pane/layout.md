
```
┌ ListHeader ─────────────────────────────────────────────────────────┐
│ [ 🔍 filter… ]                           [ …actions… ] | [ Delete ]  │
├─────────────────────────────────────────────────────────────────────┤
│  DataTable (filtered, multi-select)                        ▲ top     │
├ Details ──────── (drag anywhere on the bar) ─────────────────── ⌄ ──┤
│  details:                                                  ▼ bottom  │
│    0 selected → emptyDetail ("Select a row to see details.")         │
│    1 selected → renderDetail(row)                                    │
│   >1 selected → "Select a single row to see details."                │
└─────────────────────────────────────────────────────────────────────┘
```

- Toolbar: the shared `ListHeader` (recessed ButtonBar strip); filter `Input`
  with search icon; spacer `flex-1`; actions right-aligned.
- Details pane: `p-4 text-sm text-apt-text`; hints in `apt-text-muted`.
- The split wrapper uses `min-h-[16rem] flex-1`: `flex-1` claims the remaining
  column height, and the floor prevents the split from collapsing to 0 when the
  container is over-full (ensuring table rows remain hit-testable).
- The bottom pane is draggable + collapsible (disclosure) per `ResizableSplit`.
- No raw hex; no `!important`.

