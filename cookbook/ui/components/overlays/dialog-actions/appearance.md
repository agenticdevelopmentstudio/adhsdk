
Narrow container (no room for both at natural width) → an even split of the row:

```
┌───────────────────────────────┐
│ [   Cancel   ][   Confirm   ]  │   each capped share
└───────────────────────────────┘
```

Wide container (room for both) → natural width, right-justified:

```
┌───────────────────────────────────────────┐
│                        [ Cancel ][ Confirm]│   justify-end
└───────────────────────────────────────────┘
```

Busy:

```
┌───────────────────────────────┐
│                          ◌     │   spinner, right-justified
└───────────────────────────────┘
```

- Row: `flex items-center gap-3`; `w-full justify-end` in `auto`, `w-full` in
  forced-equal, `justify-end` in forced-natural and busy modes.
- Buttons in `auto` carry `flex-1 max-w-max`; forced-equal carries `flex-1`
  (uncapped); forced-natural carries neither.
- Buttons are the shared `Button` at `size="sm"`. Cancel is `variant="outline"`;
  confirm is `destructive` when `destructive`, else `confirmVariant` (default
  `"default"`, the gold primary).
- `data-slot="dialog-actions"` on the row for host styling/targeting.
- Busy spinner: `Loader2` at `size-4 animate-spin`, muted token color.
- No raw hex; no `!important` — buttons carry all color via `Button` variants.

