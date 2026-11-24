
- **Layout**: A row with children centered vertically and a 0.75rem gap (React/Web: `flex items-center gap-3`)
- **Toggle groups**: Uses shared ToggleGroup component for both layout and pane toggles
- **Separator**: 1px wide, border-token color, 1.25rem tall, only rendered in tabbed mode when layout toggle is visible (React/Web: `h-5 w-px bg-apt-border`)
- **Icons**: A single-pane icon, a two-column icon, a pencil and an eye (React/Web: Lucide `Square`, `Columns2`, `Pencil`, `Eye`)
- **Responsive**: Layout toggle visibility changes with viewport width (hidden below 64rem); within a wide viewport, the pane toggle and the separator between it and the layout toggle appear only in tabbed mode and disappear in split mode
