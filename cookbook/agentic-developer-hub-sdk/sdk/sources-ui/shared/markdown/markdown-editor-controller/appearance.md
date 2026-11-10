
- **Layout container**: Flex column with gap between header, control strip, and panes row. No horizontal scroll.
- **Panes row**: Flex row with gap between panes. Min-width 0 to enable flex shrinking on overflow. Min-height varies by fill mode.
- **Editor pane**: Flex column, flex-1 to fill available width in split mode. On narrow viewports (tabbed mode), displays conditionally.
- **Preview pane**: Flex column, flex-1 to fill available width in split mode. On narrow viewports (tabbed mode), displays conditionally. Border (1px), rounded corners (md), background color inherited from theme.
- **Split layout**: Editor pane takes 50% width, preview pane takes 50% width, gap between them. Both stretch to fill container height.
- **Tabbed layout**: One pane visible at a time, fills available space.
- **Min-height floor (fill mode)**: When fill is true, the panes row has a minimum height floor of 14rem (224px) so the editor's textarea has enough room to write in. When fill is false, no floor is applied; sizing follows the textarea's row count.

