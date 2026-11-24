
```
role="search"
┌──────────────────────────────────────────────┐
│ (search)  Search documents…                    │   <- Input (type=search), icon inset
└──────────────────────────────────────────────┘
┌─────────────────────┐ ┌─────────────────────┐
│ All categories    v │ │ All tags          v │   <- one Select per filter, in a row
└─────────────────────┘ └─────────────────────┘
```

- Root: `flex flex-col gap-2` when stacked, `flex flex-wrap items-center gap-2`
  when inline (+ any `className`), `role="search"` — on a `<div>`, or on a
  `<form>` when `asForm` is set.
- Search: the shared `Input` (`type="search"`, `className="pl-8"`) with a
  `lucide-react` `Search` icon absolutely positioned at the left
  (`absolute top-1/2 left-2.5 size-3.5 -translate-y-1/2 text-apt-text-muted`,
  `aria-hidden`, `pointer-events-none`).
- Filter row: `flex gap-2`, each child the shared `Select` (full-width, so two
  selects share the row evenly and stack gracefully on narrow viewports),
  followed by any `children`.
- Inline only: the search field's wrapper takes `min-w-48 flex-1` — a bare
  `flex-1` would let an empty field collapse to its icon, since a flex item's
  floor is its content width and an empty search box has none.
- Colors are inherited from the `Input`/`Select` primitives — `apt-*` tokens only,
  no raw hex, no `!important`.

