
| State | Appearance change |
|-------|------------------|
| Default (all enabled) | Buttons render in their normal variant (ghost for Cancel/Create/Delete, default for Save); text is not muted |
| Saving | Save button shows "Saving…" instead of "Save"; Delete, Cancel, and Save appear disabled with `disabled` attribute; Create does not receive `disabled` and stays clickable; Save text is muted |
| Cancel disabled | Cancel button appears grayed out / disabled |
| Save disabled (valid draft but no dirty changes) | Save button appears in ghost variant with muted text, does not accept clicks |
| Delete disabled | Delete button appears grayed out / disabled |
| Create not disabled (while saving) | Create button remains in its normal enabled appearance and stays clickable (see **create-not-disabled-while-saving**) |

