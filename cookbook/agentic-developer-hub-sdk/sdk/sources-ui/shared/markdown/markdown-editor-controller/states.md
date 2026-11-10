
| State | Description |
|-------|-------------|
| Default | Both panes visible (split layout) or editor pane visible (tabbed, default tab). |
| Editor tab active | On narrow viewports: editor pane is visible, preview is hidden. Toolbar shows "Editor" tab as selected. |
| Preview tab active | On narrow viewports: preview pane is visible, editor is hidden. Toolbar shows "Preview" tab as selected. |
| Preview rendering | After content change, debounce timer is active. Preview pane shows stale rendered content (or empty state) until debounce fires. |
| Preview ready | Debounce has fired, preview has been re-rendered with current editor content. |
| Empty content | Editor is empty or contains only whitespace. Preview pane displays placeholder message. |
| Disabled preview | The preview-availability flag is off (Apple: `isPreviewAvailable=false`) or equivalent. Only edit mode is available; preview pane is not shown; toolbar does not offer preview or split options. |
| Focused editor | Editor textarea has focus. |
| Focused overlay | Optional overlay element (e.g., typeahead listbox) has focus; overlay is positioned within the editor pane's context. |

