
```
┌───────────────────────────────────────────────────┐
│ ☐ │ Name ▲     │ Email          │ Phone           │  ← sticky header (sortable = button + caret; ☐ = select-all)
├────┼────────────┼────────────────┼─────────────────┤
│ ☐  │ Ada        │ ada@x.io       │ +1 555 0100     │  ← row (aria-selected)
│ ☑  │ Grace      │ grace@x.io     │ +1 555 0101     │  ← selected row (bg-apt-gold/15)
└────┴────────────┴────────────────┴─────────────────┘
```

- Container: `border border-apt-border rounded-lg overflow-auto`.
- Header: `bg-apt-surface-2`, sticky (`position: sticky; top: 0`), `text-apt-text-muted`, mono caption style; a sortable header is a `<button>` with a `ChevronUp`/`ChevronDown` caret in `apt-text-muted`.
- Row: `text-apt-text`, hover `bg-apt-surface-2`, selected `bg-apt-gold/15`; divider `border-t border-apt-border`.
- Selection checkbox column: width `2.75rem`, not resizable.
- Column widths come from a CSS grid template built from each column's `width` — or, with `autoSizeColumns`, from the measured width of each column's widest cell, which the user may override by dragging the column's trailing border (`cursor-col-resize`, `hover:bg-apt-gold/40`, matching the topic list's rail handle).
- Resize handle: `absolute top-0 right-0 h-full w-1.5 translate-x-1/2` on the trailing border of each resizable column header.
- No raw hex; no `!important`.

