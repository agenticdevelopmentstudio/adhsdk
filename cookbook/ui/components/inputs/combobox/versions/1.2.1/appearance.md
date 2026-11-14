
```
┌─────────────────────────────┐
│ ap|                         │   ← text input (role="combobox")
└─────────────────────────────┘
┌─────────────────────────────┐
│ ✓ Apple                     │   ← suggestion popup (filtered, anchored to the input)
│   Apricot                   │   ← active row highlighted as you arrow through
└─────────────────────────────┘
```

- Input: the shared `Input` visual language — `apt-border`, `apt-bg` background, `apt-text`, `placeholder:text-apt-text-dim`, `focus-visible` ring `apt-gold/25`.
- Popup: `apt-surface` background, `apt-border`, `shadow-lg`, anchored under the input at the input's width (`--anchor-width`), capped by `--available-height`, scrolls when long.
- Rows: dropdown row treatment — active row `bg-apt-highlight/15`; a check (`apt-gold`) marks the row equal to the current value.
- Empty: muted `apt-text-muted` message.
- No raw hex; no `!important`.

