
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Sections (set via the grouped or flat setter) | A list of sections (each with an optional title and items) | Empty | Full sectioned row model; the grouped setter groups rows with headers per non-empty section title, the flat setter wraps items in one untitled section. |
| Selection callback | A callback receiving the newly selected item, or none | none | Invoked with the newly selected item, or none, on a user-driven selection change; never invoked for a programmatic change made through selecting by id or a theme-triggered reload. |
| Title | An optional string | none | Text shown in the optional header above the list, set via the title setter; empty or unset hides the header unless a header accessory view is set. |
| Footer view | An optional view | none | Client view pinned below the list via the footer setter, spanning the sidebar width; unset collapses the footer to zero height. |
| Item menu provider | A function from an item to an optional menu | none | Builds the context menu for a secondary-clicked item row; none shows no menu. |
| Header menu provider | A function from a section title to an optional menu | none | Builds the context menu for a secondary-clicked section header row; none shows no menu. |
| Double-click callback | A callback receiving the double-clicked item | none | Invoked with an item row's item when the row is double-clicked; never for a header row. |
| Header accessory view | An optional view | none | Client view shown directly beneath the title and above the list via the accessory setter, spanning the header's width; unset collapses to nothing. |
| Drag-payload provider | A function from an item to an optional string | none | Gives the string an item row is dragged with; none, or an unset provider, makes the row not draggable. Header rows never drag. |
| Drop validator | A function from a payload string and a target item to a yes/no answer | none | Decides whether a dragged payload may be dropped onto an item row; unset, nothing can be dropped. |
| Drop callback | A callback receiving the dropped payload string and the target item | none | Invoked once for each drop the validator accepted. |
| Section accessibility identifier | An optional string, per section | none | The accessibility identifier set on the section's group header row label; none leaves the header without one. |
| Item id | A string, per item | required | The caller's key, matched by selecting an item by id and by restoring the selection after a grouped-setter call. |
| Item title | A string, per item | required | The row's label text and the source of its accessibility identifier. |
| Item icon | An optional image, per item | none | Drawn at 16x16pt before the label; none leaves the image view empty. |
| Item disabled | A yes/no flag, per item | no | Mutes the row's label, icon and subtitle; does not affect selection. |
| Item badge | An optional string, per item | none | Short trailing text after the label; none or empty shows no badge. |
| Item emphasized | A yes/no flag, per item | no | Draws the label in the bold variant of the body font. |
| Item subtitle | An optional string, per item | none | A second line under the title; none or empty draws a single-line row. |

