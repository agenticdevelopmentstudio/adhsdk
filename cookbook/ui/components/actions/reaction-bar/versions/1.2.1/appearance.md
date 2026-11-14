
```
 ┌─────────┐ ┌─────────┐
 │ 👍  3   │ │ 🎉  1   │  ☺+       ← chips (pressed / not) + palette trigger
 └─────────┘ └─────────┘
   mine        theirs    add

        ┌──────────────────────┐
        │ 👍 🎉 👀 🙏 😄 ❤️  │   ← the popover palette
        └──────────────────────┘
```

- Row: `flex flex-wrap items-center gap-1`, so a long set wraps rather than scrolls.
- Chip: the shared `Button` at `size="xs"`, `rounded-full border px-2`. A chip the viewer is
  part of is `variant="secondary"` with `border-apt-gold`; one they are not is `variant="ghost"`
  with `border-apt-border`. The count is `tabular-nums text-apt-text-dim`, so a count crossing
  9 → 10 does not shift the row.
- Palette trigger: a `size-6` circular `PopoverTrigger` holding a lucide `SmilePlus` at 14px,
  `text-apt-text-muted` brightening to `text-apt-text` on hover/focus, with an
  `apt-gold/25` focus ring.
- Palette: `PopoverContent` at `w-auto p-1.5`, aligned to the trigger's start, holding one
  `size="icon-xs"` ghost `Button` per choice.
- No raw hex; no arbitrary colors; no `!important`.

