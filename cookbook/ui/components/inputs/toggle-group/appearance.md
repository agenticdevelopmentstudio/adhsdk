
```
┌─────────────────────────────────┐   field shell (border + apt-bg, p-1)
│ ┌───────┐ ┌────────┐ ┌────────┐ │
│ │ Left  │ │ Center │ │ Right  │ │   Center pressed → gold fill
│ └───────┘ └────────┘ └────────┘ │
└─────────────────────────────────┘
   muted     GOLD       muted
```

- Group: `fieldShellClass` (`rounded-lg border border-apt-border bg-apt-bg`) +
  `inline-flex w-fit items-center gap-1 p-1`; extra classes merge via `cn()`.
- Item: `inline-flex h-8 min-w-8 items-center justify-center gap-1.5 rounded-md px-3`,
  `text-sm font-medium`, `text-apt-text-muted` at rest, `hover:text-apt-text`.
- Pressed item: `data-[pressed]:bg-apt-gold data-[pressed]:text-apt-bg`.
- Focus: `focus-visible:ring-2 focus-visible:ring-apt-gold/40`.
- Icons inside items are sized `size-4`, `shrink-0`, `pointer-events-none`.
- No raw hex; no `!important`.

