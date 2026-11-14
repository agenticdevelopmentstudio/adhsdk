
Closed:

```
┌─────────────────────────────┐
│ Choose a framework…      ▾  │   ← trigger button (committed label or placeholder) + chevron
└─────────────────────────────┘
```

Open:

```
┌─────────────────────────────┐
│ [ sv|                     ]  │   ← filter/add field — focused on open
├─────────────────────────────┤
│   SvelteKit                 │   ← filtered list (narrowed by the field text)
│ + Add "sv"                  │   ← create row: shown whenever the trimmed text is non-empty
│                              │     and has no exact case-insensitive label match — here "sv"
│                              │     substring-matches "SvelteKit" but isn't an exact match, so
│                              │     the create row appears alongside the filtered item
├─────────────────────────────┤
│              Cancel    OK   │   ← button bar; OK disabled until something is acceptable
└─────────────────────────────┘
```

- **Trigger**: Same visual language as `Select` / `Input` — `apt-border`, `apt-bg` background, `focus-visible` ring `apt-gold/25`, `ChevronsUpDown` glyph in `apt-text-muted`. Height 36px (9 units at 4px scale). Text is `apt-text`, truncated if long. On disabled state, opacity is reduced to 50% and cursor becomes `not-allowed`.
- **Surface**: `Popover` content with 8px padding (2 units). Minimum width 256px (64 units). The filter/add field uses the shared `Input` component styling. List rows use dropdown row treatment — keyboard highlight `bg-apt-highlight/15`, pointer hover `bg-apt-highlight/10`, text `apt-text`, corner radius `md` (6px). The committed row's check icon is `apt-gold`, all other icons are `apt-text-muted`. Row padding is vertical 6px × horizontal 8px (1.5 units × 2 units).
- **Create row**: A `Plus` glyph (14px, `apt-text-muted`) plus the `createLabel(text)` text, using the same row treatment as filtered items.
- **Button bar**: Separated from the list by an `apt-border` top rule (1px). Uses shared `Button` component — Cancel `variant="ghost"`, OK `variant="default"` (gold background). Buttons are small size, 32px height. Flex layout with gap 8px (2 units), justified to the end. Padding top 8px (2 units).
- **Empty message**: Shown when no items match and creation is unavailable. Text is `apt-text-muted`, 14px font size, padding 8px × 2 units.
- **Max list height**: 240px (60 units); overflow-y auto beyond that.
- **No raw hex; no `!important`**.

