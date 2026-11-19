
| State | Appearance change |
|-------|------------------|
| Default (unselected, enabled item row) | Item font, primary text color label, accent-color-tinted icon; row background follows the window-background color. |
| Disabled item row | Item font, tertiary text color label, tertiary-text-color-tinted icon, tertiary text color subtitle; identical selection/press behavior to an enabled row (see **disabled-item-selectability**). |
| Emphasized item row | The label is drawn in the bold variant of the body font; colors are unchanged. |
| With badge | A trailing label in the caption font and secondary text color, 6pt after the item label and 4pt from the cell's trailing edge; the badge keeps its full width and the item label truncates first. |
| With subtitle | A two-line row: the title, and under it the subtitle in the caption font and secondary text color. Rows without a subtitle are single-line. |
| Selected row | A 4pt-corner-radius rect, inset 2pt horizontally / 1pt vertically, filled with the theme's elevated surface color and stroked 1pt in its outline color, drawn behind the row, in a key or non-key window alike. |
| Group header row | Header font, secondary text color, marked as a group row; not selectable; no disclosure control. |
| Drop target | The component draws no drop highlight of its own: an item row a drop is offered onto shows the platform list's default drop-on-row feedback. |
| Pressed | Not applicable: this component defines no visual state distinct from Selected for a row's press - a click or an accessibility press both resolve directly to the same selection action, with no separate transient "pressed" appearance. |
| Focused | The list's focus ring is turned off, because the platform ring vanishes in a non-key window; the selected row's outline is the focus indication. |
| Loading | Not applicable: the flat and grouped setters apply their row model synchronously; source defines no async load and no loading/pending indicator. |

