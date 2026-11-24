
- **Corner radius**: None; the title cell has no border or background.
- **Padding**: None set on the title cell; spacing comes from the strip that holds it.
- **Font**: monospace (`font-mono`), `text-[0.8rem]` (12.8px exact), letter-spacing `tracking-[0.02em]`; weight is not set and inherits the ambient weight.
- **Background**: None; the strip's own background shows through.
- **Foreground/Text**: `text-apt-text-muted` (semantic muted text token).
- **Border**: None.
- **Shadow**: None.
- **Min/Max size**: `min-w-0 flex-1`, so the cell fills the strip's remaining width and may shrink below its content width; overflow is cut with `truncate` (hidden overflow, ellipsis, no wrapping).

