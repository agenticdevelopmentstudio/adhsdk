
- **Corner radius**: Root `0.5rem` (`--aws-radius`); sidebar rows `0.375rem` (`--aws-radius-sm`).
- **Padding**: Sidebar `1rem` vertical × `0.5rem` horizontal; sidebar row `0.45rem` × `0.6rem`; detail area `1.5rem` on all sides (`--aws-content-padding`).
- **Font**: Root uses the themed sans family; sidebar title `1rem`, weight 600; rows `0.875rem`; section titles `0.65rem`, weight 600, uppercase, letter spacing `0.08em`.
- **Background**: Root and detail area use the surface token (`--aws-bg`, default `#0c0c0f`); sidebar uses the raised-surface token (`--aws-surface`, default `#14141a`); hovered row uses `--aws-surface-hover`; selected row uses `--aws-accent-dim`.
- **Foreground/Text**: Root text uses `--aws-text`; section titles use the muted token `--aws-text-muted`; the icon is muted and turns to `--aws-accent` on the selected row.
- **Border**: Root has a 1px solid `--aws-border` border; the sidebar has a 1px right border in `--aws-border`; rows have a 1px transparent border.
- **Shadow**: None.
- **Min/Max size**: Root is `100%` wide, `100%` tall, minimum height `360px`, with overflow hidden; sidebar width `220px` (`--aws-sidebar-width`) and does not shrink; the sidebar and detail area each scroll vertically on overflow; icon box `1rem` × `1rem`.
- **Layout**: Root is a flex row; the sidebar is a flex column with `0.75rem` gap; rows are flex rows with `0.55rem` gap and fill the sidebar width.
- **Theming**: Colors and fonts resolve from the toolkit's `--color-*` and `--font-*` custom properties with literal fallbacks, declared on `.aws-panel` and its sibling family classes and overridable by consumers.

