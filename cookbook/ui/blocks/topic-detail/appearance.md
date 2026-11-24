
- **Grid**: `grid-cols-1` below `md`; from `md` the columns are the `--rail-w` variable (full `railWidth`, default `FULL_RAIL` 240px; collapsed `COLLAPSED_RAIL` 48px) and `minmax(0,1fr)`.
- **Rail**: `bg-apt-nav`, `border-r border-apt-border`, flex column; the list scrolls with `pr-4 pt-2` (`pr-1` collapsed) and `pb-8` (`pb-2` with `denseBottom`).
- **Row**: monospace `0.8rem`, tracking `0.02em`, `border-l-2` transparent, `gap-2 pt-1 pb-0.5`, `pl-2` (`pl-8` in batch mode), `pr-3` (`pr-9` when deletable); collapsed rows centre their icon with `py-1.5`. Sublabel and preview are `0.7rem` in `text-apt-text-dim`.
- **Row colour**: default `text-apt-text`; active `text-apt-gold` with `border-l-apt-gold` in bar style; hover `border-l-apt-text`; disabled `text-apt-text-dim`.
- **Blocked dot**: 6px `bg-apt-orange` with a 2px `ring-apt-nav` punch-out at the icon's top-right.
- **Delete button**: 19px, absolute at right 3px, `bg-apt-nav text-apt-text-dim`, opacity 0 until row hover or focus, `hover:text-apt-red`, `ring-apt-red/40` on focus.
- **Header**: `min-h-[2.15rem]`, `pl-2.5 pr-2`, `border-b`; toolbar `min-h-[2rem]`, same inset and border; title `0.8rem` mono `text-apt-text-muted`.
- **Tools**: `ListToolButton` is `p-0.5 rounded`, `text-apt-text-muted` (gold when active), `hover:text-apt-text`, `ring-apt-gold/40` on focus.
- **Filter panel**: `absolute inset-0` over the toolbar, `bg-apt-surface`; suggestions hang below it, `max-h-72` capped to the room left in the clipping box, `shadow-lg`, highlighted option `bg-apt-gold/15`.
- **Dividers**: `h-px bg-apt-border`. **Drag handle**: 6px wide, `cursor-col-resize`, `hover:bg-apt-gold/40`.
- **Pane**: `bg-apt-surface`, `overflow-auto`, flex column. No raw colour values.

