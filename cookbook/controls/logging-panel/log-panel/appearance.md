
- **Container**: Grid-based layout with header and scrollable body sections
- **Column header cells**: Display column title; text alignment per column.align; default is left-aligned (start)
- **Body cells**: Display cell text; font, color, and weight applied per cell and column properties
- **Empty state**: Centered, gray text message when no rows are visible
- **Scrollbar**: Native to the OS; appears when content exceeds maxHeight
- **Cell background**: Transparent by default; cell text inherits color from level or custom color
- **Cell padding**: Not specified in source; stylesheet is expected to define via CSS classes
- **Monospace font**: Applied via CSS variable `--font-mono` or system fallback `ui-monospace, SFMono-Regular, monospace`
- **Level colors**: Text color is determined by mapping the log level (`cell.level`, falling back to `column.defaultLevel`) to a CSS variable with a platform-color fallback:

  | Level | CSS Variable | Fallback |
  |-------|--------------|----------|
  | info | `--lp-color-info` | `var(--color-text-primary, #1a1a24)` |
  | warn | `--lp-color-warn` | `var(--color-warn, #b45309)` |
  | error | `--lp-color-error` | `var(--color-error, #c0392b)` |
  | success | `--lp-color-success` | `var(--color-success, #1f7a4d)` |
  | debug | `--lp-color-debug` | `var(--color-text-secondary, rgba(0,0,0,0.55))` |
  | dim | `--lp-color-dim` | `var(--color-text-dim, rgba(0,0,0,0.45))` |
  | accent | `--lp-color-accent` | `var(--color-accent, #1e3a5f)` |

  `cell.color`, when provided, overrides the level-based color entirely.

