
```
┌ Add users ─────────────────────────────────────────────────────┐
│  DataTable: Name · Email · Phone · Admin note                   │  staged rows
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Ada     │ ada@x.io   │ +1 555 0100 │ priority             │  │
│  └──────────────────────────────────────────────────────────┘  │
│  [ name ][ email ][ phone ][ admin note ]        ……    [ Add ]  │  entry row
│                                                                 │
│                                       [ Cancel ]   [ Add ]      │  footer
└─────────────────────────────────────────────────────────────────┘
```

- `DialogContent` (`max-w-2xl` — the table needs width); the staged `DataTable`
  above; the entry row a `flex items-end gap-2` of `Field`-wrapped `Input`s + a
  `flex-1` spacer + the Add `Button`. Footer right-justified `[ Cancel ][ Add ]`.
- The staged table supports `DataTable` selection (`selectedIds` /
  `onSelectionChange`); at minimum the table shows what is queued.
- No raw hex; no `!important`.

