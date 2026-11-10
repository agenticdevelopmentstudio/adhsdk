
Tabs use the shared tab styling defined by `tabItemClass` and `tabListClass` from the `tabs` ingredient (see depends-on).

- **Corner radius**: 0 (no rounding; `tabItemClass` has no `rounded-*` utility).
- **Padding**: `tabListClass` puts a 16px gap between items (`gap-4`); each tab (`tabItemClass`) has 8px vertical / 4px horizontal padding (`py-2 px-1`).
- **Font**: Monospace, 0.8rem (12.8px), tracking-wide letter-spacing (`font-mono text-[0.8rem] tracking-wide`).
- **Background**: Transparent; no fill on the root, list, or individual tabs.
- **Foreground/Text**: Muted gray by default (`text-apt-text-muted`); full-contrast text on hover, focus-visible, or when active (`data-[active]:text-apt-text`).
- **Border**: The list has a 1px bottom border (`border-b border-apt-border`); the active tab shows a 2px gold bottom border (`data-[active]:border-apt-gold`) that overlaps the list's border via a negative margin (`-mb-px`); inactive tabs reserve the same 2px of space with a transparent border.
- **Shadow**: None.
- **Min/Max size**: No explicit width/height constraint; computed tab height is approximately 33px (`text-[0.8rem]`'s ~15px line-height + `py-2`'s 16px total vertical padding + the 2px border).

