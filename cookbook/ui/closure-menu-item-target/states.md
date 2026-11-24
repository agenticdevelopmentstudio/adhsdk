
| State | Appearance change |
|-------|------------------|
| Default | Item is enabled and its checked mark is untouched (no checked closure) or follows the checked closure. |
| Pressed | Not applicable: the perform message runs the action closure; the component keeps no pressed state. |
| Disabled | Enabled closure returns false: the menu system shows the item disabled and does not send the perform message. |
| Focused | Not applicable: the component is not a view; focus belongs to the menu system. |
| Loading | Not applicable: the component runs synchronously and has no loading state. |
| Checked | Checked closure returns true: the item shows a checkmark (state on). |
| Unchecked | Checked closure returns false: the item shows no checkmark (state off). |

