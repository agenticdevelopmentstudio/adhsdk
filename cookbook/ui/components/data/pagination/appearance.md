
```
[ Prev ]     Page 3 of 5     [ Next ]
 outline      mono, muted      outline
 size sm      xs caption       size sm
```

- Row: `nav` with `flex items-center justify-center gap-2`, centered; extra classes
  merge via `cn()` through `className`.
- `Prev` / `Next`: the shared `Button` with `variant="outline"` and `size="sm"`, plain
  text labels.
- Caption: `<span>` with `px-1 font-mono text-xs text-apt-text-muted`, reading
  `Page {page} of {totalPages}`.
- Disabled edge buttons inherit `Button`'s disabled treatment (`opacity-50`,
  `pointer-events-none`).
- Token-driven (`apt-text-muted`); no raw hex, no `!important`.

