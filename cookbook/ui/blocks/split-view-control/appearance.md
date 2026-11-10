
- **Layout**: Flex row, `items-center` (vertical center alignment), `gap-3` (0.75rem spacing)
- **Toggle groups**: Uses shared ToggleGroup component for both layout and pane toggles
- **Separator**: 1px width, `bg-apt-border` color, height 1.25rem (h-5), only rendered in tabbed mode when layout toggle is visible
- **Icons**: Lucide React icons (Square, Columns2, Pencil, Eye)
- **Responsive**: Layout toggle visibility changes with viewport width (hidden below 64rem); within a wide viewport, the pane toggle and the separator between it and the layout toggle appear only in tabbed mode and disappear in split mode
- **Custom className**: The component MUST accept an optional `className` prop and merge it with the base flex layout using `cn()` utility

