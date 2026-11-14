
```
toolbar ─────────────────────────────────────────────
  […other controls]  [✓ Check spelling  (3)]   ← toggle Button (outline, sm);
                              │                   SpellCheck icon + label +
                              │                   count Badge (error) when open
                              ▼ on enable (popover, side=bottom align=end, w-80)
  ┌ SPELLING & GRAMMAR ───────────────────────────┐
  │ ┌───┐                                          │
  │ │teh│  Did you mean "the"?                      │  ← flagged chip (mono, red)
  │ └───┘  [✓ the]                                  │     + message + apply chips
  │ ──────────────────────────────────────────────│
  │ recieve  Did you mean "receive"?                │
  │          [✓ receive]                            │
  └────────────────────────────────────────────────┘
       states: Checking… (spinner) · No issues found. · unavailable (red)
```

- Toggle: shared `Button` via `buttonVariants({ variant: "outline", size: "sm" })`
  with a leading `SpellCheck` icon; an error-tone `Badge` shows the open problem
  count.
- Panel: the shared `PopoverContent` (`bg-apt-surface`, `border-apt-border`,
  `text-apt-text`), `w-80`, `max-h-[24rem] overflow-auto`.
- Caption: `fieldCaptionClass` (from typography utilities).
- Each problem: a `<li>` with the flagged text in a `rounded bg-apt-surface-2`
  mono chip (`text-apt-red`), the message in `text-xs text-apt-text-muted`, and
  apply chips as the shared `Button` (`variant="outline" size="xs"`) with a
  `Check` icon.
- Tokens only: `apt-*` surfaces/text/borders/semantics; no raw hex, no
  `!important`.

